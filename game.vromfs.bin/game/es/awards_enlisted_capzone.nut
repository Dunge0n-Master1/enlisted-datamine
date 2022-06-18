import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let {EventAwardZoneCapturers, EventCapZoneEnter} = require("dasevents")
let {addAward} = require("awards.nut")

// TODO: make ecs components
const CAPSCORES_CAPTURE_FINAL = 1.0
const CAPSCORES_CAPTURE_PARTICIPATE = 0.5

let function getVisitorPlayerEid(visitorEid) { //get squad.ownerPlayer of hero or bot by squad
  let squadEid = ecs.obsolete_dbg_get_comp_val(visitorEid, "squad_member__squad") ?? INVALID_ENTITY_ID
  return ecs.obsolete_dbg_get_comp_val(squadEid, "squad__ownerPlayer") ?? INVALID_ENTITY_ID
}

let getSoldierData = @(eid, teamId = TEAM_UNASSIGNED) {
  eid = eid
  squadEid = ecs.obsolete_dbg_get_comp_val(eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  guid = ecs.obsolete_dbg_get_comp_val(eid, "guid") ?? ""
  teamId = teamId
}

let function awardPlayer(playerEid) {
  if (playerEid != INVALID_ENTITY_ID)
    addAward(playerEid, "capture", {scoreId="captures"})
}

let function addZonePlayerPresence(visitorEid, comp) {
  let playerEid = getVisitorPlayerEid(visitorEid)
  if (playerEid == INVALID_ENTITY_ID)
    return
  let teamId = ecs.obsolete_dbg_get_comp_val(visitorEid, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED || teamId == comp["capzone__owningTeam"])
    return

  if (comp["capzone__capturersEids"].indexof(playerEid, ecs.TYPE_EID) == null)
    comp["capzone__capturersEids"].append(playerEid, ecs.TYPE_EID)

  let sData = getSoldierData(visitorEid, teamId)
  local hasSoldier = false
  foreach(s in comp["capzone__soldiersCapture"])
    if (s.guid == sData.guid && s.squadEid == sData.squadEid) {
      hasSoldier = true
      break
    }

  if (!hasSoldier)
    comp["capzone__soldiersCapture"][visitorEid.tostring()] = sData
}

let function awardZoneCapturers(_, comp) {
  let awardPlayers = {} //eid = bool, true - was at capture end, or has bot on capture end
  let awardSoldiers = [] //award only soldiers who was on point when capture finish
  foreach(eid in comp["capzone__capturersEids"]) {
    let teamId = ecs.obsolete_dbg_get_comp_val(eid, "team", TEAM_UNASSIGNED)
    if (teamId == comp["capzone__owningTeam"])
      awardPlayers[eid] <- false
  }
  foreach(s in comp["capzone__soldiersCapture"].getAll())
    if (s.teamId == comp["capzone__owningTeam"])
      awardSoldiers.append(s.__merge({ stat = "captures", amount = CAPSCORES_CAPTURE_PARTICIPATE }))
  let capscoreBySquad = {}

  foreach (team in comp["teamPresence"])
    foreach (eid in team) {
      let playerEid = getVisitorPlayerEid(eid)
      if (playerEid != INVALID_ENTITY_ID)
        awardPlayers[playerEid] <- true

      let sData = getSoldierData(eid)
      let awardData = awardSoldiers.findvalue(@(s) s.guid == sData.guid && s.squadEid == sData.squadEid)
      if (awardData != null) {
        awardData.amount = CAPSCORES_CAPTURE_FINAL
        capscoreBySquad[sData.squadEid] <- CAPSCORES_CAPTURE_FINAL
      }
    }

  let presenceAmountBySquad = {}
  foreach (awardData in awardSoldiers)
    presenceAmountBySquad[awardData.squadEid] <- (presenceAmountBySquad?[awardData.squadEid] ?? 0) + awardData.amount
  awardSoldiers.each(function(s) {
    let squadPresenceTotalAmount = presenceAmountBySquad?[s.squadEid] ?? 0
    let squadCaptureScore = capscoreBySquad?[s.squadEid] ?? CAPSCORES_CAPTURE_PARTICIPATE
    if (squadPresenceTotalAmount > 0)
      s.amount *= squadCaptureScore / squadPresenceTotalAmount
  })

  foreach(playerEid, isFinal in awardPlayers)
    if (isFinal) {
      ecs.g_entity_mgr.sendEvent(playerEid, ecs.event.EventPlayerSquadFinishedCapturing())
      awardPlayer(playerEid)
    }

  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = awardSoldiers }))
  comp["capzone__capturersEids"].clear()
  comp["capzone__soldiersCapture"] = {}
}

ecs.register_es("track_capzone_presence_for_awards", {
  [EventCapZoneEnter] = @(evt, _eid, comp) addZonePlayerPresence(evt.visitor, comp),
}, {
  comps_rw = [
    ["capzone__capturersEids", ecs.TYPE_EID_LIST],
    ["capzone__soldiersCapture", ecs.TYPE_OBJECT],
  ]
  comps_ro = [
    ["capzone__owningTeam", ecs.TYPE_INT],
  ]
}, {tags="server"})

ecs.register_es("award_on_capzone_captured", {
  [EventAwardZoneCapturers] = awardZoneCapturers,
}, {
  comps_rw = [
    ["capzone__capturersEids", ecs.TYPE_EID_LIST],
    ["capzone__soldiersCapture", ecs.TYPE_OBJECT],
    ["teamPresence", ecs.TYPE_OBJECT],
  ]
  comps_ro = [
    ["capzone__owningTeam", ecs.TYPE_INT],
  ]
}, {tags="server"})