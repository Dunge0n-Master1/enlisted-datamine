import "%dngscripts/ecs.nut" as ecs
let { get_can_use_respawnbase_type } = require("%enlSqGlob/spawn_base.nut")
let {find_respawn_base_for_team_with_type, count_vehicles_of_type} = require("%scripts/game/utils/respawn_base.nut")
let {get_sync_time} = require("net")
let {EventEntityActivate} = require("dasevents")

let respawnerComps = {
  comps_ro = [
    ["respawner__respTime", ecs.TYPE_FLOAT],
    ["respawner__respStartTime", ecs.TYPE_FLOAT, -1.0],
    ["respawner__canRespawnTime", ecs.TYPE_FLOAT, -1.0],
    ["respawner__respEndTime", ecs.TYPE_FLOAT, -1.0],
  ]
  comps_rw = [
    ["respawner__vehicleRespawnsBySquad", ecs.TYPE_ARRAY]
  ]
}

let respawnerQuery = ecs.SqQuery("respawnerQuery", respawnerComps)
let playerQuery = ecs.SqQuery("playerQuery", {
  comps_ro = [
    ["team", ecs.TYPE_INT],
    ["armies", ecs.TYPE_OBJECT],
    ["army", ecs.TYPE_STRING]
  ],
  comps_rw = [
    ["vehicleRespawnsBySquad", ecs.TYPE_ARRAY]
  ]
})

let function gatherAllRespawnbaseTypesInSquads(squads) {
  let respTypes = {}
  foreach (i, squad in squads) {
    let { canUseRespawnbaseType = null, canUseRespawnbaseSubtypes = [] } = get_can_use_respawnbase_type(squad?.curVehicle.gametemplate)
    if (canUseRespawnbaseType != null) {
      let key = canUseRespawnbaseSubtypes.len() > 0 ? "{0}+{1}".subst(canUseRespawnbaseType,"+".join(canUseRespawnbaseSubtypes)) : canUseRespawnbaseType
      if (key in respTypes)
        respTypes[key].squadIndices.append(i)
      else
        respTypes[key] <- { respType = canUseRespawnbaseType, subtypes = canUseRespawnbaseSubtypes, squadIndices = [i] }
    }
  }
  return respTypes
}

let function onTimerChanged(_evt, eid, comp) {
  local vehicleRespawnsBySquad = comp["respawner__vehicleRespawnsBySquad"].getAll()

  foreach (item in vehicleRespawnsBySquad) {
    item.respInVehicleEndTime = -1.0
    item.maxSpawnVehiclesOnPoint = -1
  }

  playerQuery.perform(eid, function(_eid, playerComps) { // TODO: FIXME it's the same entity, no need for another query!
    let playerTeam = playerComps["team"]
    let armyData = playerComps.armies?[playerComps.army]
    let playerVehicleRespawnsBySquad = playerComps["vehicleRespawnsBySquad"].getAll()

    vehicleRespawnsBySquad = array(playerVehicleRespawnsBySquad.len()).map(@(_) {
      respInVehicleEndTime = -1.0
      maxSpawnVehiclesOnPoint = -1
    })

    let curTime = get_sync_time()

    foreach (respawnType in gatherAllRespawnbaseTypesInSquads(armyData?.squads ?? [])) {
      let { respType, subtypes, squadIndices } = respawnType
      let baseEid = find_respawn_base_for_team_with_type(playerTeam, respType, subtypes)
      if (baseEid == INVALID_ENTITY_ID)
        continue
      local spawnFreq = ecs.obsolete_dbg_get_comp_val(baseEid, "respTime", 0)
      local maxSpawnVehiclesOnPoint = ecs.obsolete_dbg_get_comp_val(baseEid, "maxVehicleOnSpawn", 0)

      if (count_vehicles_of_type(playerTeam, respType) < maxSpawnVehiclesOnPoint)
        maxSpawnVehiclesOnPoint = -1

      foreach (i in squadIndices) {
        if (playerVehicleRespawnsBySquad?[i] == null)
          continue

        let firstSpawnAtTime = playerVehicleRespawnsBySquad[i]?.firstSpawnAtTime ?? 0.0
        let firstSpawnDelay = firstSpawnAtTime - curTime
        let isFirstSpawn    = firstSpawnDelay > 0.0
        if (isFirstSpawn)
          spawnFreq = firstSpawnDelay

        let lastSpawnOnVehicleAtTime = isFirstSpawn ? curTime : playerVehicleRespawnsBySquad[i].lastSpawnOnVehicleAtTime
        let timeToSpawn = spawnFreq != 0 && lastSpawnOnVehicleAtTime != 0 ? lastSpawnOnVehicleAtTime + spawnFreq : -1

        vehicleRespawnsBySquad[i].maxSpawnVehiclesOnPoint = maxSpawnVehiclesOnPoint
        vehicleRespawnsBySquad[i].respInVehicleEndTime = timeToSpawn

        playerVehicleRespawnsBySquad[i].nextSpawnOnVehicleInTime = timeToSpawn
      }
    }

    playerComps["vehicleRespawnsBySquad"] = playerVehicleRespawnsBySquad
  })

  comp["respawner__vehicleRespawnsBySquad"] = vehicleRespawnsBySquad
}

let function onVehiclesCountChanged(evt, _eid, _comp) {
  respawnerQuery.perform(function(spawnerEid, spawnerComp){
      onTimerChanged(evt, spawnerEid, spawnerComp)
  })
}

ecs.register_es("vehicles_spawn_enabler_es", {
  [[EventEntityActivate, "onDestroy", "onInit", ecs.EventComponentChanged]] = onTimerChanged,
}, respawnerComps, {tags="server", track = "respawner__respEndTime,respawner__respStartTime,respawner__canRespawnTime"})

ecs.register_es("vehicles_count_changed_es", {
  [["onInit", "onChange"]] = onVehiclesCountChanged,
}, {
  comps_ro    = [["team", ecs.TYPE_INT], ["canUseRespawnbaseType", ecs.TYPE_STRING]]
  comps_track = [["isAlive", ecs.TYPE_BOOL]]
  comps_rq    = ["vehicle"]
}, {tags="server"})