import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
/*

This code looks like piece of spaghetti because it has
all things are tightened up and overcomplicated
and this is just ugly and really awful
*/


let { EventOnSpawnError } = require("%enlSqGlob/sqevents.nut")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let vehiclesData = require("%ui/hud/state/vehiclesData.nut")
let app = require("net")
let { sendNetEvent, CmdRequestRespawn, CmdCancelRequestRespawn, RequestNextRespawnEntity
} = require("dasevents")
let { mkCountdownTimerPerSec } = require("%ui/helpers/timers.nut")
let logHR = require("%enlSqGlob/library_logs.nut").with_prefix("[HERO_RESPAWN]")
let { localPlayerTeam, localPlayerEid } = require("%ui/hud/state/local_player.nut")
let armyData = require("armyData.nut")
let soldiersData = require("soldiersData.nut")
let vehicleRespawnBases = require("%ui/hud/state/vehicleRespawnBases.nut")
let { get_can_use_respawnbase_type } = require("das.respawn")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { spawnZonesState } = require("%ui/hud/state/spawn_zones_markers.nut")
let humanCanRespawn = require("%ui/hud/state/humanCanRespawn.nut")

let respEndTime = mkWatched(persist, "respEndTime", -1)
let canRespawnTime = mkWatched(persist, "canRespawnTime", -1)
let canRespawnWaitNumber = mkWatched(persist, "canRespawnWaitNumber", -1)
let respawnerEid = mkWatched(persist, "respawnerEid", ecs.INVALID_ENTITY_ID)
let canChangeRespawnParams = Computed(@() respEndTime.value > 0 || canRespawnTime.value > 0 || canRespawnWaitNumber.value > 0)

let spawnedSquadsStorage = mkOnlineSaveData("spawnedSquads")
let setSpawnedSquads = spawnedSquadsStorage.setValue
let curSpawnedSquads = spawnedSquadsStorage.watch
console_register_command(@() setSpawnedSquads(null), "ui.resetSpawnedSquads")

let squadsCanSpawn = mkWatched(persist, "squadsCanSpawn", true)
let respawnsInBot = mkWatched(persist, "respawnsInBot", false)
let respawnLastActiveTime = mkWatched(persist, "respawnLastActiveTime", -1)
let respawnInactiveTimeout = mkWatched(persist, "respawnInactiveTimeout", -1)
let curSoldierIdx = mkWatched(persist, "curSoldierIdx", 0)
let squadIndexForSpawn = Watched(-1)
let selectedRespawnGroupId = Watched({})

let queuedRespawnGroupId = Watched(-1)
let queueRespawnGroupId = Watched(-1)

let vehicleInfo = Computed(function() {
  let { guid = null, skin = null } = armyData.value?.squads[squadIndexForSpawn.value].curVehicle
  let vehicle = vehiclesData.value?[guid]
  if (vehicle == null)
    return null

  let override = skin == null ? {} : { skin }
  return vehicle.__merge(override)
})

let canUseRespawnbaseByType = Computed(@() get_can_use_respawnbase_type(vehicleInfo.value?.gametemplate)?.canUseRespawnbaseType ?? "human")
let currentRespawnGroup = Computed(@() selectedRespawnGroupId.value?[canUseRespawnbaseByType.value] ?? -1)

let squadMemberIdForSpawn = mkWatched(persist, "squadMemberIdForSpawn", 0)
let squadsRevivePoints = mkWatched(persist, "squadsRevivePoints", [])
let soldierRevivePoints = mkWatched(persist, "soldierRevivePoints", [])
let isSpectatorEnabled = mkWatched(persist, "isSpectatorEnabled", false)
let maxSpawnVehiclesOnPointBySquad = mkWatched(persist, "maxSpawnVehiclesOnPointBySquad", [])
let nextSpawnOnVehicleInTimeBySquad = mkWatched(persist, "nextSpawnOnVehicleInTimeBySquad", [])
let spawnSquadId = mkWatched(persist, "spawnSquadId")
let spawnCount = mkWatched(persist, "spawnCount", 0)
let isFirstSpawn = mkWatched(persist, "isFirstSpawn", false)

//control - can be changed by server or by ui
let respRequested = mkWatched(persist, "respRequested", false)

let needSpawnMenu = Computed(@() (respawnsInBot.value || squadsCanSpawn.value) && canChangeRespawnParams.value)
let showSquadSpawn = Computed(@() needSpawnMenu.value && !respawnsInBot.value)
let timeToCanRespawn = mkCountdownTimerPerSec(canRespawnTime)
let isSquadAvailableByTime = Watched([])
let canSpawnOnVehicleBySquad = Computed(@() maxSpawnVehiclesOnPointBySquad.value.map(@(maxVehicles, k) maxVehicles == -1 && (isSquadAvailableByTime.value?[k] ?? true)))

let function updateVehicleSpawnAvailableTimer(...) {
  let curTime = app.get_sync_time()
  isSquadAvailableByTime(nextSpawnOnVehicleInTimeBySquad.value.map(@(v) v <= curTime))
  let nextEndTime = nextSpawnOnVehicleInTimeBySquad.value
    .filter(@(it) it > curTime)
    .reduce(@(a,b) min(a,b)) ?? -1.0
  let minDelay = nextEndTime - curTime
  if (minDelay > 0) {
    gui_scene.clearTimer(updateVehicleSpawnAvailableTimer)
    gui_scene.setTimeout(minDelay, updateVehicleSpawnAvailableTimer)
  }
}
nextSpawnOnVehicleInTimeBySquad.subscribe(updateVehicleSpawnAvailableTimer)
updateVehicleSpawnAvailableTimer()

let function requestRespawn() {
  let squadId = squadIndexForSpawn.value
  let spawnGroup = currentRespawnGroup.value
  let memberId = squadMemberIdForSpawn.value
  let curSpawnSquadId = spawnSquadId.value
  setSpawnedSquads((curSpawnedSquads.value ?? {}).__merge({ [curSpawnSquadId] = true }))
  logHR($"Request respawn, respawnerEid {respawnerEid.value}, squadId {squadId}, memberId {memberId}")
  sendNetEvent(respawnerEid.value, CmdRequestRespawn({ squadId = squadId, memberId = memberId, spawnGroup = spawnGroup }))
}

let function cancelRequestRespawn() {
  let squadId = squadIndexForSpawn.value
  let memberId = squadMemberIdForSpawn.value
  let spawnGroup = queueRespawnGroupId.value
  logHR($"Request cancel respawn, respawnerEid {respawnerEid.value}, squadId {squadId}, memberId {memberId}")
  sendNetEvent(respawnerEid.value, CmdCancelRequestRespawn({ squadId = squadId, memberId = memberId, spawnGroup = spawnGroup }))
  queuedRespawnGroupId(queueRespawnGroupId.value)
}

let hasVehicleRespawns = Computed(@() vehicleRespawnBases.value.eids.len() > 0)
let squadsList = Computed(function(prev) {
  if (!needSpawnMenu.value) //we no need to recalc squads while not in the respawn screen.
    return prev != FRP_INITIAL ? prev : []
  let armyId = armyData.value?.armyId
  return (armyData.value?.squads ?? [])
    .map(function(squad, idx) {
      let squadId = squad.squadId
      let squadDesc = squadsPresentation?[armyId][squadId]
      local { premIcon = null } = squadDesc
      if ((squad?.battleExpBonus ?? 0) > 0)
        premIcon = premIcon ?? armiesPresentation?[armyId].premIcon
      let readinessPercent = squadsRevivePoints.value?[idx] ?? -1
      local canSpawn = readinessPercent == 100
      if (canSpawn) {
        if (squad?.curVehicle != null) {
          let { canUseRespawnbaseType = null, canUseRespawnbaseSubtypes = [] } = get_can_use_respawnbase_type(squad.curVehicle?.gametemplate)
          let availableRespSubtypes = hasVehicleRespawns.value ? (vehicleRespawnBases.value.byType?[canUseRespawnbaseType] ?? {}) : {}
          let hasRespawnbase = availableRespSubtypes.len() > 0
            && (canUseRespawnbaseSubtypes.len() == 0 || canUseRespawnbaseSubtypes.findvalue(@(subtype) availableRespSubtypes?[subtype]))
          let canSpawnOnVehicle = canSpawnOnVehicleBySquad.value?[idx] ?? false
          canSpawn = hasRespawnbase && canSpawnOnVehicle && readinessPercent == 100
        } else {
          canSpawn = humanCanRespawn.value
        }
      }

      return {
        squadId
        icon = squadDesc?.icon
        premIcon
        name = squad?.locId ? loc(squad.locId) : "---"
        squadType = squad?.squadType ?? "unknown"
        level = squad?.level ?? 0
        squadSize = squad.squad.len()
        vehicle = squad?.curVehicle
        vehicleType = squad?.vehicleType
        isFaded = !canSpawn

        canSpawn = canSpawn
        readinessPercent = readinessPercent
      }
    })
  }
)

let function cancelRespawn() {
  if (respRequested.value)
    respRequested(false)
  else if (queueRespawnGroupId.value != queuedRespawnGroupId.value)
    respRequested.trigger()
}

let function onActive() {
  respawnLastActiveTime(app.get_sync_time())
  cancelRespawn()
}

armyData.subscribe(@(data) spawnSquadId(data?.curSquadId))

let function updateSquadSpawnIndex(...) {
  squadIndexForSpawn(squadsList.value.findindex(@(s) s.squadId == spawnSquadId.value) ?? 0)
}

spawnSquadId.subscribe(function(_) {
  updateSquadSpawnIndex()
  onActive()
})
squadsList.subscribe(updateSquadSpawnIndex)

curSoldierIdx.subscribe(function(i){
  squadMemberIdForSpawn(i)
  onActive()
})

let function getBestSquadId(squads, curSquadId, defSquadId = null) {
  local bestSquadId = (squads.findindex(@(sq) sq.squadId == curSquadId) == null ? null : curSquadId)
    ?? defSquadId

  local maxReadiness = squads.findvalue(@(sq)
    sq.squadId == bestSquadId && sq.canSpawn)?.readinessPercent ?? 0
  foreach (squad in squads)
    if (squad.canSpawn && squad.readinessPercent > maxReadiness) {
      bestSquadId = squad.squadId
      maxReadiness = squad.readinessPercent
    }
  return bestSquadId
}

let function updateSpawnSquadId() {
  let squads = squadsList.value
  let spawnedSquads = curSpawnedSquads.value
  let preferSquads = squads.filter(@(s) s.squadId not in spawnedSquads)
  let curSpawnSquadId = spawnSquadId.value
  let bestSquadId = getBestSquadId(preferSquads, curSpawnSquadId)
    ?? getBestSquadId(squads, curSpawnSquadId, squads?[0].squadId)

  spawnSquadId(bestSquadId)
}

let curSquadData = Computed(@()
  squadsList.value.findvalue(@(val) val?.squadId == spawnSquadId.value))

let soldiersList = Computed(function() {
  let squadId = spawnSquadId.value
  let squads = armyData.value?.squads ?? []
  let armyId = armyData.value?.armyId
  let squadIndx = squads.findindex(@(s) s.squadId == squadId)
  let squad = squads?[squadIndx]
  let readinessPercents = soldierRevivePoints.value?[squadIndx] ?? []
  return (squad?.squad ?? [])
    .map(function(s) {
      let { premIcon = null } = squadsPresentation?[armyId][squadId]
      return soldiersData.value?[s.guid].__merge({
        canSpawn = (readinessPercents?[s.id] ?? 100) == 100
        premIcon = premIcon ?? (s?.isPremium ?? false) ? armiesPresentation?[armyId].premIcon : null
      })
    })
    .filter(@(s) s != null)
})

let respawnBlockedReason = Computed(function() {
  let zones = spawnZonesState.value
  let respawnId = currentRespawnGroup.value
  let canUse = canUseRespawnbaseByType.value
  let lpt = localPlayerTeam.value
  foreach (zone in zones) {
    if (zone?.forTeam == lpt && zone?.selectedGroup == respawnId && canUse == zone.iconType){
      if (!zone.isActive && zone.enemyAtRespawn)
        return  {reason = "respawn/enemy_at_respawn"}
      if (canRespawnWaitNumber.value > 0)
        return  {reason = "respawn/waiting_in_queue", waitNumber = canRespawnWaitNumber.value, timeToActivate = zone.activateAtTime}
      if (!zone.isActive && zone.activateAtTime > 0.0)
        return {reason = "respawn/blocked_by_timer", timeToActivate = zone.activateAtTime}
      if (!zone.isActive)
        return {reason = "respawn/respawn_disabled"}
    }
  }
  return {}
})

let canSpawnCurrentSoldier = Computed(@() soldiersList.value?[curSoldierIdx.value]?.canSpawn ?? true)
let canSpawnCurrentSquadAndSoldier = Computed(@() (curSquadData.value?.canSpawn ?? false) && canSpawnCurrentSoldier.value)
let canSpawnCurrent = Computed(@() !respawnBlockedReason.value?.reason && canSpawnCurrentSquadAndSoldier.value)

currentRespawnGroup.subscribe(function(v) {
  queueRespawnGroupId(canSpawnCurrentSquadAndSoldier.value ? v : -1)
  onActive()
})

canSpawnCurrentSquadAndSoldier.subscribe(function(v) {
  if (!v) {
    queueRespawnGroupId(-1)
    cancelRespawn()
  }
  else if (!respRequested.value) {
    queueRespawnGroupId(currentRespawnGroup.value)
    cancelRespawn()
  }
})

canSpawnCurrent.subscribe(function(v){
  if (!v)
    cancelRespawn()
})

let findReadySoldier = @(squadIndex) soldierRevivePoints.value?[squadIndex]?.findindex(@(readinessPercent) readinessPercent == 100)

soldiersList.subscribe(function(_) {
  curSoldierIdx(squadIndexForSpawn.value < 0 ? 0 : findReadySoldier(squadIndexForSpawn.value) ?? 0)
})

let respEndTotalTime = Computed(function(){
  if (!canSpawnCurrent.value || !needSpawnMenu.value)
    return -1
  if (respEndTime.value > 0)
    return respEndTime.value
  if (respawnLastActiveTime.value > 0 )
    return max(canRespawnTime.value, respawnLastActiveTime.value + respawnInactiveTimeout.value)
  return -1
})

let timeToRespawn = mkCountdownTimerPerSec(respEndTotalTime)

//This is espically ugly code
local isChangedByUi = true
respRequested.subscribe(function(v) {
  if (isChangedByUi) {
    if (v)
      requestRespawn()
    else
      cancelRequestRespawn()
  }
})

needSpawnMenu.subscribe(function(need) { if (need) respawnLastActiveTime(app.get_sync_time()) })
local pendingResp = null

let function setPendingResp(_) {
  if (pendingResp)
    return
  //wait for all watches update their values before send respawn event
  pendingResp = function() {
    pendingResp = null
    logHR("Check pending resp. respEndTime = {0}, respEndTotalTime = {1}, timeToRespawn = {2} "
      .subst(respEndTime.value, respEndTotalTime.value, timeToRespawn.value))
    if (needSpawnMenu.value && respEndTime.value <= 0 && respEndTotalTime.value > 0
        && timeToRespawn.value == 0)
      requestRespawn()
  }
  defer(pendingResp)
}
foreach (w in [needSpawnMenu, respEndTime, respEndTotalTime, timeToRespawn])
  w.subscribe(setPendingResp)

let function equalUpdate(watch, newVal) {
  if (!isEqual(watch.value, newVal))
    watch(newVal)
}

let function trackComponents(_evt, eid, comp) {
  if (!comp.is_local)
    return
  respawnerEid(eid)
  canRespawnTime(comp["respawner__canRespawnTime"])

  let waitNumber = comp["respawner__canRespawnWaitNumber"]
  if (canRespawnWaitNumber.value > 0 && waitNumber == 0)
    gui_scene.resetTimeout(0.1, @() canRespawnWaitNumber(waitNumber))
  else
    canRespawnWaitNumber(waitNumber)

  respEndTime(comp["respawner__respEndTime"])
  respawnsInBot(comp["respawner__respToBot"])
  respawnInactiveTimeout(comp["respawner__respawnWhenInactiveTimeout"])
  isFirstSpawn(comp["respawner__isFirstSpawn"])
  isSpectatorEnabled(comp["respawner__spectatorEnabled"])
  equalUpdate(maxSpawnVehiclesOnPointBySquad, comp.respawner__vehiclesLimitBySquad.getAll())
  equalUpdate(nextSpawnOnVehicleInTimeBySquad, comp.respawner__nextSpawnOnVehicleTimeBySquad.getAll())
  isChangedByUi = false
  logHR("Received from server respawner__respRequested = {0}, respawner__respEndTime = {1}, respawner__canRespawnTime = {2}, respawner__canRespawnWaitNumber = {3}"
    .subst(comp["respawner__respRequested"], comp["respawner__respEndTime"], comp["respawner__canRespawnTime"], comp["respawner__canRespawnWaitNumber"]))
  respRequested(comp["respawner__respRequested"])
  isChangedByUi  = true
}

ecs.register_es("respawns_state_ui_es", {
    [["onInit","onChange",ecs.EventScriptReloaded]] = trackComponents,
  },
  {
    comps_track = [
      ["respawner__respToBot", ecs.TYPE_BOOL],
      ["respawner__respEndTime", ecs.TYPE_FLOAT, -1.0],
      ["respawner__canRespawnTime", ecs.TYPE_FLOAT, -1.0],
      ["respawner__canRespawnWaitNumber", ecs.TYPE_INT, -1],
      ["respawner__respawnWhenInactiveTimeout", ecs.TYPE_FLOAT, -1.0],
      ["respawner__respawnWhenInactiveShowTimer", ecs.TYPE_FLOAT, -1.0],
      ["respawner__respRequested", ecs.TYPE_BOOL, false],
      ["respawner__isFirstSpawn", ecs.TYPE_BOOL, false],
      ["respawner__vehiclesLimitBySquad", ecs.TYPE_INT_LIST],
      ["respawner__nextSpawnOnVehicleTimeBySquad", ecs.TYPE_INT_LIST],
      ["respawner__spectatorEnabled", ecs.TYPE_BOOL, false],
      ["is_local", ecs.TYPE_BOOL],
    ]
  }
)

let function trackSquadComponents(_evt, _eid, comp) {
  if (!comp.is_local)
    return
  equalUpdate(squadsRevivePoints, comp["squads__revivePointsList"]?.getAll() ?? [])
  spawnCount(comp["squads__spawnCount"])
  squadsCanSpawn(comp["squads__squadsCanSpawn"])
}

ecs.register_es("squads_state_ui_es", {
    [["onInit","onDestroy","onChange"]] = trackSquadComponents,
}, {
  comps_track = [
    ["squads__revivePointsList", ecs.TYPE_INT_LIST],
    ["squads__spawnCount", ecs.TYPE_INT],
    ["squads__squadsCanSpawn", ecs.TYPE_BOOL],
    ["is_local", ecs.TYPE_BOOL],
  ]
})

ecs.register_es("solder_revive_points_state_ui_es", {
    [["onInit","onDestroy","onChange"]] = function(_evt, _eid, comp) {
      if (comp.is_local)
        equalUpdate(soldierRevivePoints, comp["soldier_revive_points__points"]?.getAll() ?? [])
    }
}, {
  comps_track = [
    ["soldier_revive_points__points", ecs.TYPE_ARRAY],
    ["is_local", ecs.TYPE_BOOL],
  ]
})


ecs.register_es("squads_state_show_respawn_ui_es",
  {[EventOnSpawnError] = @ (evt, _eid, _comp) logHR($"Spawn Error: {evt.data.reason}")},
  {comps_rq = ["player"]})

let requestRespawnToEntity = @(eid)
  sendNetEvent(localPlayerEid.value, RequestNextRespawnEntity({memberEid=eid}))

let state = {
  respEndTime
  canRespawnTime
  canRespawnWaitNumber
  respawnsInBot
  canChangeRespawnParams
  canUseRespawnbaseByType
  squadIndexForSpawn
  vehicleInfo
  squadsCanSpawn
  selectedRespawnGroupId
  isSpectatorEnabled
  maxSpawnVehiclesOnPointBySquad
  nextSpawnOnVehicleInTimeBySquad
  respRequested
  spawnSquadId
  spawnCount
  isFirstSpawn
  needSpawnMenu
  timeToCanRespawn
  canSpawnOnVehicleBySquad
  timeToRespawn
  showSquadSpawn
  squadsList
  curSquadData
  canSpawnCurrent
  canSpawnCurrentSoldier
  soldiersList
  curSoldierIdx
  respawnBlockedReason
  // functions
  updateSpawnSquadId
  requestRespawnToEntity
}

let debugSpawn = mkWatched(persist,"debugSpawn")
let beforeDebugSpawn = mkWatched(persist, "beforeDebugSpawn")

let function setDebugMode(isRespawnInBot) {
  let isChanged = debugSpawn.value?.respawnsInBot != isRespawnInBot
  if (!isChanged) {
    foreach (key, value in beforeDebugSpawn.value)
      state[key](value)
    beforeDebugSpawn(null)
    debugSpawn(null)
    return
  }
  let newData = {
    respawnsInBot = isRespawnInBot
    respEndTime = 300 + app.get_sync_time()
    canRespawnTime = 35 + app.get_sync_time()
    canRespawnWaitNumber = -1
  }
  debugSpawn(newData)
  if (!beforeDebugSpawn.value)
    beforeDebugSpawn(newData.map(@(_value, key) state[key].value))
  foreach (key, value in newData)
    state[key](value)
}

console_register_command(@() setDebugMode(false), "respawn.debugSquad")
console_register_command(@() setDebugMode(true), "respawn.debugMember")

return state