import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let {logerr} = require("dagor.debug")
let {get_sync_time} = require("net")
let {EventForceCapture, EventAwardZoneCapturers, EventCapZoneLeave, EventCapZoneEnter,
       EventZoneIsAboutToBeCaptured, EventZoneDeactivated, EventZoneCaptured, EventZoneStartCapture, EventZoneStartDecapture, EventZoneDecaptured, EventFirstPlayerSpawned,
       broadcastNetEvent, EventEntityActivate, EventZoneUnlock} = require("dasevents")
let {server_broadcast_net_sqevent} = require("ecs.netevent")

let capStatus = {
  DECAPTURE = 2
  CAPTURE = 1
  UNKNOWN = 0
}

let MULTIPLE_TEAMS = -2 // a magic number to show that there is more than one team on zone.

let function startCap(zone_eid, comp, team) {
  ecs.clear_timer({eid=zone_eid, id="capzone"})
  comp["capzone__capTeam"] = team
  comp["capzone__capTeamEid"] = get_team_eid(team) ?? INVALID_ENTITY_ID
  comp["capzone__captureStatus"] = capStatus.CAPTURE
  ecs.set_timer({eid=zone_eid, id="capzone", interval=comp["capzone__timerPeriod"], repeat=true})
  ecs.g_entity_mgr.broadcastEvent(EventZoneStartCapture({eid=zone_eid, team=team}))
}


let function startDecap(zone_eid, comp, prev_capturing_team, capturing_team) {
  ecs.clear_timer({eid=zone_eid, id="capzone"})
  let team = comp["capzone__capTeam"]
  if (team == TEAM_UNASSIGNED && !comp["capzone__decapOnNeutral"]) {
    comp["capzone__progress"]= 0.0
    comp["capzone__capTeam"] = TEAM_UNASSIGNED
    comp["capzone__captureStatus"]=capStatus.UNKNOWN
    comp["capzone__owningTeam"] = TEAM_UNASSIGNED
  }
  else {
    ecs.set_timer({eid=zone_eid, id="capzone", interval=comp["capzone__timerPeriod"], repeat=true})
    comp["capzone__captureStatus"]=capStatus.DECAPTURE
    ecs.g_entity_mgr.broadcastEvent(EventZoneStartDecapture({eid=zone_eid, team=team}))
    if (prev_capturing_team != capturing_team) {
      if ((prev_capturing_team > 0) && (team != prev_capturing_team))
        server_broadcast_net_sqevent(ecs.event.EventTeamEndDecapture({eid=zone_eid, team=prev_capturing_team}))
      if (capturing_team > 0)
        server_broadcast_net_sqevent(ecs.event.EventTeamStartDecapture({eid=zone_eid, team=capturing_team}))
    }
  }
}

let function onTeamDominateZone(zone_eid, comp, team) {
  let capTeam = comp["capzone__capTeam"]
  let curProgress = comp["capzone__progress"]
  if (capTeam == team || capTeam == TEAM_UNASSIGNED) {
    if (curProgress < 1.0) {
      startCap(zone_eid, comp, team)
      comp["capzone__curTeamCapturingZone"] = team
    }
  }
  else if (curProgress > 0.0) {
    startDecap(zone_eid, comp, comp["capzone__curTeamCapturingZone"], team)
    comp["capzone__curTeamCapturingZone"] = team
  }
  else {
    startCap(zone_eid, comp, team)
    comp["capzone__curTeamCapturingZone"] = team
  }
}

let function onZoneTieOrNeutral(zone_eid, comp, numTeamsPresent) {
  let prevCapturingTeam = comp["capzone__curTeamCapturingZone"];
  comp["capzone__curTeamCapturingZone"] = (numTeamsPresent > 1) ? MULTIPLE_TEAMS : TEAM_UNASSIGNED
  let curProgress = comp["capzone__progress"]
  if (curProgress >= 0.0 && curProgress < 1.0) {
    ecs.clear_timer({eid=zone_eid, id="capzone"})
    if (comp["capzone__autoDecap"] || (comp["capzone__owningTeam"] == TEAM_UNASSIGNED && comp["capzone__autoCap"]))
      startDecap(zone_eid, comp, prevCapturingTeam, comp["capzone__curTeamCapturingZone"])
    else if (comp["capzone__autoCap"])
      startCap(zone_eid, comp, comp["capzone__owningTeam"])
  }
}

let function onTeamPresenceChanged(zone_eid, comp) {
  if (!comp.active)
    return

  let gap = comp["capzone__presenceAdvantageToDominate"]
  local numTeamsPresent = 0
  local dominatingTeam = TEAM_UNASSIGNED
  local maxPresenceNum = 1 - gap
  local advantage = 0
  let advantageWeights = comp["capzone__advantageWeights"]?.getAll() ?? {}
  foreach (tid, team in comp["teamPresence"]) {
    local teamPresenceNum = team.len()
    let weight = advantageWeights?[tid]
    if (weight != null)
      teamPresenceNum *= weight.tointeger()
    if (teamPresenceNum > 0) {
      if (teamPresenceNum >= maxPresenceNum + gap) {
        dominatingTeam = tid.tointeger()
      } else if (teamPresenceNum > maxPresenceNum - gap) {
        dominatingTeam = MULTIPLE_TEAMS
      }
      if (teamPresenceNum > maxPresenceNum) {
        advantage = max(0, teamPresenceNum - (maxPresenceNum + gap - 1))
        maxPresenceNum = teamPresenceNum
      } else {
        advantage = clamp(maxPresenceNum - (teamPresenceNum + gap - 1), 0, advantage)
      }
      numTeamsPresent++
    }
  }
  comp["capzone__capTeamAdvantage"] = advantage
  comp["capzone__isMultipleTeamsPresent"] = numTeamsPresent > 1

  let onlyTeamCanCap = comp["capzone__onlyTeamCanCapture"]
  let allowDecap = comp["capzone__allowDecap"]
  let curProgress = comp["capzone__progress"]
  let isNumberDomination = comp["capzone__canCaptureByPresenceDomination"]

  let isTeamDominating = numTeamsPresent == 1 || (isNumberDomination && dominatingTeam >= 0)
  let isTeamCanCapture = (onlyTeamCanCap == TEAM_UNASSIGNED || onlyTeamCanCap == dominatingTeam || (allowDecap && curProgress == 1.0))

  comp.capzone__curTeamDominating = (isTeamDominating && isTeamCanCapture) ? dominatingTeam : TEAM_UNASSIGNED

  if (comp.capzone__locked)
    return

  if (isTeamDominating && isTeamCanCapture)
    onTeamDominateZone(zone_eid, comp, dominatingTeam)
  else
    onZoneTieOrNeutral(zone_eid, comp, numTeamsPresent)
}

let function getAdvantageSpeedMult(canCaptureByPresenceDomination, advantage, advantageDivisor) {
  if (!canCaptureByPresenceDomination || advantageDivisor <= 0)
    return 1.0
  return advantage / advantageDivisor
}

let getMinCapDecapSpeedMult = @(advantageDivisor) advantageDivisor > 0.0 ? 1.0 / advantageDivisor : 1.0

local deactivationTimer = null
local deactivationCallback = null

let function captureZone(zone_eid, comp) {
  comp["capzone__progress"] = 1.0
  comp["capzone__captureStatus"] = capStatus.UNKNOWN

  if (comp["capzone__deactivateAfterCap"] && !comp["capzone__checkAllZonesInGroup"])
    comp["active"] = false // forcefully deactivate, so nobody will be able to push any events to it

  let reCap = comp["capzone__owningTeam"] == comp["capzone__capTeam"]
  let deactivateAfterTimeout = comp["capzone__deactivateAfterTimeout"]
  if (deactivateAfterTimeout > 0.0) {
    if (comp["capzone__owningTeam"] != comp["capzone__capTeam"]) {
      let capTeam = comp["capzone__capTeam"]

      broadcastNetEvent(EventZoneIsAboutToBeCaptured({zone=zone_eid, team=capTeam}))

      let respawnBaseEid = comp["capzone__respawnBaseEid"]
      deactivationCallback = function () {
        deactivationTimer = null
        ecs.g_entity_mgr.broadcastEvent(EventZoneDeactivated({zone=zone_eid, team=capTeam}))
        ecs.g_entity_mgr.destroyEntity(respawnBaseEid)
      }
      deactivationTimer = ecs.set_callback_timer(deactivationCallback, deactivateAfterTimeout, false)
    }
  }
  else if (comp["capzone__owningTeam"] != comp["capzone__capTeam"] ||
           comp["capzone__checkAllZonesInGroup"])
    broadcastNetEvent(EventZoneCaptured({zone=zone_eid, team=comp["capzone__capTeam"]}))

  comp["capzone__owningTeam"] = comp["capzone__capTeam"]
  if (!reCap)
    ecs.g_entity_mgr.sendEvent(zone_eid, EventAwardZoneCapturers())
}

let function onForceCapture(evt, zone_eid, comp) {
  let team = evt?.team ?? TEAM_UNASSIGNED
  if (team != TEAM_UNASSIGNED) {
    comp["capzone__capTeam"] = team
    captureZone(zone_eid, comp)
  }
}

let function onCapTimer(_evt, zone_eid, comp) {
  let progress = comp["capzone__progress"]
  let capTeamEid = comp["capzone__capTeamEid"]
  let capSpeedMult = ecs.obsolete_dbg_get_comp_val(capTeamEid, "team__captureSpeedMult", 1.0)
  let advantageMult = getAdvantageSpeedMult(comp["capzone__canCaptureByPresenceDomination"], comp["capzone__capTeamAdvantage"],
                                            comp["capzone__advantageDivisor"])
  let minCapSpeedMult = getMinCapDecapSpeedMult(comp["capzone__advantageDivisor"])
  let maxCapSpeedMult = comp["capzone__maxCapDecapSpeedMult"]
  let capSpeed = (1.0 / comp["capzone__capTime"]) * clamp(capSpeedMult * advantageMult, minCapSpeedMult, maxCapSpeedMult)
  let progressDelta = capSpeed * comp["capzone__timerPeriod"]

//  if (progress < 0.5 && progress + progressDelta >= 0.5)
//    server_broadcast_net_sqevent(ecs.event.EventZoneHalfCaptured({eid=zone_eid, team=comp["capzone__capTeam"]}))

  if (progress + progressDelta >= 1.0)
    captureZone(zone_eid, comp)
  else
    comp["capzone__progress"] = progress + progressDelta
}


let function onDecapTimer(_evt, zone_eid, comp) {
  let progress = comp["capzone__progress"]
  let team = comp["capzone__capTeam"]
  if (progress == 1.0 && comp["capzone__autoDecap"]) {
    print($"zone {zone_eid} decaptured(1)")
    broadcastNetEvent(EventZoneDecaptured({zone=zone_eid, team}))
  }
  let advantageMult = getAdvantageSpeedMult(comp["capzone__canCaptureByPresenceDomination"], comp["capzone__capTeamAdvantage"],
                                            comp["capzone__advantageDivisor"])
  let minDecapSpeedMult = getMinCapDecapSpeedMult(comp["capzone__advantageDivisor"])
  let maxDecapSpeedMult = comp["capzone__maxCapDecapSpeedMult"]
  let decapSpeed = (1.0 / comp["capzone__decapTime"]) * clamp(advantageMult, minDecapSpeedMult, maxDecapSpeedMult)
  let progressDelta = decapSpeed * comp["capzone__timerPeriod"]
  if (progressDelta >= progress) {
    comp["capzone__progress"] = 0.0
    comp["capzone__capTeam"]= TEAM_UNASSIGNED
    comp["capzone__captureStatus"] = capStatus.UNKNOWN
    if (!comp["capzone__autoDecap"])
      broadcastNetEvent(EventZoneDecaptured({zone=zone_eid, team=comp["capzone__owningTeam"]}))
    comp["capzone__owningTeam"] = TEAM_UNASSIGNED
    let capTeam = comp["capzone__curTeamCapturingZone"]
    if (capTeam > 0)
      server_broadcast_net_sqevent(ecs.event.EventTeamEndDecapture({eid=zone_eid, team=capTeam}))
    onTeamPresenceChanged(zone_eid, comp)
  }
  else
    comp["capzone__progress"]=progress - progressDelta
}


let function onTimer(evt, zone_eid, comp) {
  if (comp["capzone__captureStatus"] == capStatus.CAPTURE)
    onCapTimer(evt, zone_eid, comp)
  else if (comp["capzone__captureStatus"] == capStatus.DECAPTURE)
    onDecapTimer(evt, zone_eid, comp)
  else
    ecs.clear_timer({eid=zone_eid, id="capzone"})
}


let function onZoneEnter(evt, zone_eid, comp) {
  let visitor = evt.visitor
  local teamId = ecs.obsolete_dbg_get_comp_val(visitor, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED)
    return
  teamId = teamId.tostring()
  let teamPresence = comp["teamPresence"]
  if (teamId in teamPresence) {
    teamPresence[teamId].append(visitor)
  }
  else
    teamPresence[teamId] <- [visitor]
  onTeamPresenceChanged(zone_eid, comp)
}

let function onZoneLeave(evt, zone_eid, comp) {
  let visitor = evt.visitor
  local teamId = ecs.obsolete_dbg_get_comp_val(visitor, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED)
    return
  teamId = teamId.tostring()
  let teamPresence = comp["teamPresence"]
  if (teamId in teamPresence) {
    let idx = teamPresence[teamId].indexof(visitor)
    if (idx != null)
      teamPresence[teamId].remove(idx)
  }
  else
    teamPresence[teamId] <- [] // reset to zero
  onTeamPresenceChanged(zone_eid, comp)
}


let function onZoneActivate(evt, zone_eid, comp) {
  if (evt.activate)
    onTeamPresenceChanged(zone_eid, comp)
  else
    ecs.clear_timer({eid=zone_eid, id="capzone"})
}

let function onZoneUnlock(_evt, zone_eid, comp) {
  onTeamPresenceChanged(zone_eid, comp)
}

let function onZoneChange(evt, comp, def, count) {
  local teamId = ecs.obsolete_dbg_get_comp_val(evt.visitor, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED)
    return
  teamId = teamId.tostring()
  let presenceTeamCount = comp["capzone__presenceTeamCount"]
  if (teamId in presenceTeamCount)
    presenceTeamCount[teamId] += count
  else
    presenceTeamCount[teamId] <- def
}

/*
teampresence :
{
  "1" = {"0"="eid1", "1"="eid2"}, where "1" is team__id
  "2" = {"0"="eid1", "1"="eid2"},
}
There is no way to have arrays in objects currently, so it seems weird and not optimal
However this is still important, cause we now can have hot reload for capzone
*/

let comps = {
  comps_rw = [
    ["capzone__capTeam", ecs.TYPE_INT],
    ["capzone__owningTeam", ecs.TYPE_INT],
    ["capzone__capTeamEid", ecs.TYPE_EID],
    ["capzone__curTeamCapturingZone", ecs.TYPE_INT],
    ["teamPresence", ecs.TYPE_OBJECT],
    ["capzone__captureStatus", ecs.TYPE_INT],
    ["capzone__isMultipleTeamsPresent", ecs.TYPE_BOOL],
    ["capzone__progress", ecs.TYPE_FLOAT],
    ["active", ecs.TYPE_BOOL],
    ["capzone__capTeamAdvantage", ecs.TYPE_INT],
    ["capzone__curTeamDominating", ecs.TYPE_INT],
  ]
  comps_ro = [
    ["capzone__onlyTeamCanCapture", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["capzone__allowDecap", ecs.TYPE_BOOL, false],
    ["capzone__capTime", ecs.TYPE_FLOAT, 20.0],
    ["capzone__decapTime", ecs.TYPE_FLOAT, 30.0],
    ["capzone__timerPeriod", ecs.TYPE_FLOAT, 1.0/3.0],
    ["capzone__deactivateAfterCap",ecs.TYPE_BOOL, false],
    ["capzone__checkAllZonesInGroup",ecs.TYPE_BOOL, false],
    ["capzone__decapOnNeutral",ecs.TYPE_BOOL, false],
    ["capzone__autoDecap",ecs.TYPE_BOOL, true],
    ["capzone__autoCap",ecs.TYPE_BOOL, true],
    ["capzone__deactivateAfterTimeout", ecs.TYPE_FLOAT, -1.0],
    ["capzone__respawnBaseEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["capzone__presenceAdvantageToDominate", ecs.TYPE_INT, 1],
    ["capzone__canCaptureByPresenceDomination", ecs.TYPE_BOOL, false],
    ["capzone__advantageDivisor", ecs.TYPE_FLOAT, 4.0],
    ["capzone__maxCapDecapSpeedMult", ecs.TYPE_FLOAT, 2.0],
    ["capzone__advantageWeights", ecs.TYPE_OBJECT, null],
    ["capzone__locked", ecs.TYPE_BOOL, false]
  ]
}

ecs.register_es("capzone_es", {
  [EventCapZoneEnter] = onZoneEnter,
  [EventCapZoneLeave] = onZoneLeave,
  [EventEntityActivate] = onZoneActivate,
  [EventZoneUnlock] = onZoneUnlock,
  Timer = onTimer,
}, comps, {tags="server"})

ecs.register_es("force_cap_zone_es", {
  [EventForceCapture] = onForceCapture,
}, {
  comps_rw = [
    ["capzone__capTeam", ecs.TYPE_INT],
    ["capzone__owningTeam", ecs.TYPE_INT],
    ["capzone__captureStatus", ecs.TYPE_INT],
    ["capzone__progress", ecs.TYPE_FLOAT],
    ["active", ecs.TYPE_BOOL],
  ]
  comps_ro = [
    ["capzone__deactivateAfterCap",ecs.TYPE_BOOL, false],
    ["capzone__checkAllZonesInGroup",ecs.TYPE_BOOL, false],
    ["capzone__deactivateAfterTimeout", ecs.TYPE_FLOAT, -1.0],
    ["capzone__respawnBaseEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
  ]
}, {tags="server"})

ecs.register_es("capzone_change_es", {
  [EventCapZoneEnter] = @(evt, _, comp) onZoneChange(evt, comp, 1, 1),
  [EventCapZoneLeave] = @(evt, _, comp) onZoneChange(evt, comp, 0, -1)
},
{
  comps_rw = [["capzone__presenceTeamCount", ecs.TYPE_OBJECT]]
}, {tags="server"})

ecs.register_es("capzone_first_enter_es", {
  [EventCapZoneEnter] = function(evt, _eid, comp) {
    let visitor = evt.visitor
    let team = ecs.obsolete_dbg_get_comp_val(visitor, "team", TEAM_UNASSIGNED)
    if (team != TEAM_UNASSIGNED && comp["capzone__onlyTeamCanCapture"] == team) {
      if (comp["capzone__respawnBaseEid"] != INVALID_ENTITY_ID) {
        ecs.g_entity_mgr.destroyEntity(comp["capzone__respawnBaseEid"])
        comp["capzone__respawnBaseEid"] = INVALID_ENTITY_ID
      }
      if (deactivationTimer) {
        ecs.clear_callback_timer(deactivationTimer)
        deactivationCallback()
      }
    }
  }
},
{
  comps_rw=[["capzone__respawnBaseEid", ecs.TYPE_EID]]
  comps_ro=[["capzone__onlyTeamCanCapture", ecs.TYPE_INT], ["capzone__capTeam", ecs.TYPE_INT]]
  comps_rq=["capzone__deactivateAfterTimeout"]
},
{tags="server"})

let createRespawnBase = @(templ, transform, groupName, team) ecs.g_entity_mgr.createEntity(templ, {
  active = true
  transform = transform
  groupName = groupName
  team = team
})

let createRespawnBaseGroupActivator = @(templ, groupName, groupId, team) ecs.g_entity_mgr.createEntity(templ, {
  ["respawn_activator__active"] = true,
  ["respawn_activator__groupId"] = groupId,
  ["respawn_activator__groupName"] = groupName,
  ["respawn_activator__team"] = team
})

let function startRespawnTimoutTimer(respawnBase, timeout) {
  ecs.set_callback_timer(function() {
    ecs.g_entity_mgr.destroyEntity(respawnBase)
  }, timeout, false)
}

let firstPlayerSpawnTimeQuery = ecs.SqQuery("firstPlayerConnectionQuery", {comps_ro=[["firstPlayerSpawnTime", ecs.TYPE_FLOAT]]})
let getFirstSpawnTime = @() firstPlayerSpawnTimeQuery(@(_, comp) comp.firstPlayerSpawnTime) ?? -1.0

ecs.register_es("capzone_create_respbase_es", {
  [["onInit", "onChange"]] = function(_eid, comp) {
    let spawnAtZoneTimeout = comp["capzone__spawnAtZoneTimeout"]
    if (!comp.active || spawnAtZoneTimeout <= 0.0)
      return
    let templName = comp["capzone__createRespawnBase"]
    let team = comp["capzone__createRespawnBaseForTeam"]
    if (team == TEAM_UNASSIGNED) {
      logerr("capzone__createRespawnBaseForTeam must be set in the mission. Or capzone__spawnAtZoneTimeout must be removed.")
      return
    }
    if (comp["capzone__respawnBaseEid"] != INVALID_ENTITY_ID)
      ecs.g_entity_mgr.destroyEntity(comp["capzone__respawnBaseEid"])
    let respawnBaseGroupId = comp["capzone__createdRespawnBaseGroup"]
    comp["capzone__respawnBaseEid"] = respawnBaseGroupId < 0 ?
                                     createRespawnBase($"{templName}+temporary_respawn_base", comp.transform, comp.groupName, team) :
                                     createRespawnBaseGroupActivator(templName, comp.groupName, respawnBaseGroupId, team)
    let startTime = getFirstSpawnTime()
    if (startTime >= 0.0) {
      let timerTime = max(spawnAtZoneTimeout, startTime + spawnAtZoneTimeout - get_sync_time())
      startRespawnTimoutTimer(comp["capzone__respawnBaseEid"], timerTime)
    }
  },
  [EventFirstPlayerSpawned] = function(_eid, comp) {
    let spawnAtZoneTimeout = comp["capzone__spawnAtZoneTimeout"]
    let respawnBase = comp["capzone__respawnBaseEid"]
    if (comp.active && spawnAtZoneTimeout > 0.0)
      startRespawnTimoutTimer(respawnBase, spawnAtZoneTimeout)
  },
  [EventZoneIsAboutToBeCaptured] = function(evt, eid, comp) {
    let zoneEid = evt.zone
    let capTeam = evt.team
    if (eid != zoneEid)
      return
    if (comp["capzone__respawnBaseEid"] != INVALID_ENTITY_ID)
      ecs.g_entity_mgr.destroyEntity(comp["capzone__respawnBaseEid"])
    if (comp["capzone__createRespawnBaseForAttackTeam"]){
      let respawnBaseGroupId = comp["capzone__createdRespawnBaseGroup"]
      let templName = comp["capzone__createRespawnBase"]
      comp["capzone__respawnBaseEid"] = respawnBaseGroupId < 0 ?
                                       createRespawnBase(templName, comp.transform, comp.groupName, capTeam) :
                                       createRespawnBaseGroupActivator(templName, comp.groupName, respawnBaseGroupId, capTeam)
    }
  }
},
{
  comps_track=[["active", ecs.TYPE_BOOL]]
  comps_rw=[["capzone__respawnBaseEid", ecs.TYPE_EID]]
  comps_ro=[
    ["transform", ecs.TYPE_MATRIX],
    ["groupName", ecs.TYPE_STRING],
    ["capzone__onlyTeamCanCapture", ecs.TYPE_INT],
    ["capzone__createRespawnBase", ecs.TYPE_STRING],
    ["capzone__createRespawnBaseForTeam", ecs.TYPE_INT],
    ["capzone__spawnAtZoneTimeout", ecs.TYPE_FLOAT],
    ["capzone__createdRespawnBaseGroup", ecs.TYPE_INT],
    ["capzone__createRespawnBaseForAttackTeam", ecs.TYPE_BOOL, false],
  ]
},
{tags="server"})

ecs.register_es("capzone_deactivate_temporary_respbase_es", {
  onChange = function(_eid, comp) {
    if (!comp.active && deactivationTimer) {
      ecs.clear_callback_timer(deactivationTimer)
      deactivationCallback()
    }
  }
},
{
  comps_track=[["active", ecs.TYPE_BOOL]]
  comps_rq=["temporaryRespawnbase"]
},
{tags="server"})
