import "%dngscripts/ecs.nut" as ecs
let {fill_walkable_positions_around} = require("navmesh")
let {TMatrix} = require("dagor.math")

let onWaveTimerQuery = ecs.SqQuery("onWaveTimerQuery", {comps_ro=["possessed", "team"], comps_rq=["player"]})

let function onWaveTimer(eid, comp){
  print("onWaveTimer")
  let teamToSpawnFor = ecs.obsolete_dbg_get_comp_val(eid, "team")
  let minionTeam = ecs.obsolete_dbg_get_comp_val(eid, "minion_spawner__spawnTeam")
  let allPositions = []
  let playerPositions = []
  let spawnDist = comp["minion_spawner__spawn_distance"]
  let spawnDistSq = spawnDist * spawnDist
  local playerDiff = 0
  onWaveTimerQuery.perform(function(_playerEid, playerComp){
    let plrTeam = playerComp["team"]
    playerDiff += plrTeam == teamToSpawnFor ? 1 : plrTeam == minionTeam ? -1 : 0
    let peid = playerComp["possessed"]
    if (peid == INVALID_ENTITY_ID || !ecs.obsolete_dbg_get_comp_val(peid, "isAlive", false) || plrTeam != teamToSpawnFor)
      return

    let tm = ecs.obsolete_dbg_get_comp_val(peid, "transform")
    if (tm==null) {
      return
    }
    let position = tm.getcol(3)
    playerPositions.append(position)
    let potentialPositions = array(comp["minion_spawner__min_wave_size"] * 2)
    if (fill_walkable_positions_around(position, potentialPositions, spawnDist, 1.0))
      foreach (pos in potentialPositions)
        allPositions.append({position = pos, weight = 0.0})
  })
  foreach (pos in allPositions) {
    foreach (playerPos in playerPositions) {
      let lenSq = (pos.position - playerPos).lengthSq()
      if (lenSq < spawnDistSq)
        pos.weight += lenSq - spawnDistSq
    }
  }
  allPositions.sort(@(a,b) a.weight <=> b.weight)
  if (allPositions.len() == 0)
    ecs.set_timer({eid=eid, id="wave_timer", interval = 0.5, repeat = false}) // fast retry
  else
    ecs.set_timer({eid=eid, id="wave_timer", interval = comp["minion_spawner__wave_period"], repeat = false})
  let baseSize = comp["minion_spawner__base_wave_size"]
  let diffSz = comp["minion_spawner__diff_wave_size"]
  let perPlayerSz = comp["minion_spawner__per_player_wave_size"]
  let template = comp["minion_spawner__template"]
  let wishNumber = baseSize + playerDiff * diffSz + playerPositions.len() * perPlayerSz
  for (local i = 0; i < min(allPositions.len(), wishNumber); ++i) {
    let transform = TMatrix()
    transform.setcol(3, allPositions[i].position.x, allPositions[i].position.y, allPositions[i].position.z)
    let comps = {
      transform = [transform, ecs.TYPE_MATRIX],
      team = [minionTeam, ecs.TYPE_INT],
    }
    ecs.g_entity_mgr.createEntity(template, comps)
  }
}

let function onInit(eid, _comp){
 ecs.clear_timer({eid=eid, id="wave_timer"})
 ecs.set_timer({eid=eid, id="wave_timer", interval = 0.5, repeat = false})
}

let comps = {
  comps_ro = [
    ["minion_spawner__wave_period", ecs.TYPE_FLOAT, 15.0],
    ["minion_spawner__base_wave_size", ecs.TYPE_INT, 1],
    ["minion_spawner__per_player_wave_size", ecs.TYPE_INT, 1],
    ["minion_spawner__diff_wave_size", ecs.TYPE_INT, 1],
    ["minion_spawner__template", ecs.TYPE_STRING],
    ["minion_spawner__min_wave_size", ecs.TYPE_INT, 1],
    ["minion_spawner__spawn_distance", ecs.TYPE_FLOAT],
    ["minion_spawner__spawnTeam", ecs.TYPE_INT]
  ]
}

ecs.register_es("minion_spawner_es", {
  Timer = onWaveTimer
  onInit = onInit
}, comps, {tags = "server"})


