import "%dngscripts/ecs.nut" as ecs
let {EventAwardZoneCapturers, EventPlayerSquadHelpedToDestroyPoint} = require("dasevents")
let getSoldierInfoFromCache = require("%scripts/game/es/soldier_info_cache.nut")
let {addAward} = require("awards.nut")

let function getSoldierInfo(eid) {
  let {player=INVALID_ENTITY_ID, guid=""} = getSoldierInfoFromCache(eid) ?? {}
  return (player != INVALID_ENTITY_ID && guid != "")
    ? {playerEid=player, guid}
    : null
}

let collectParticipantsInfo = @(participants)
  participants.map(@(contribution, eid) getSoldierInfo(eid)?.__merge({contribution}))
              .values()
              .filter(@(value) value != null)

let function groupByPlayer(data) {
  let res = {}
  foreach (v in data) {
    let key = v?.playerEid
    if (key != null)
      res[key] <- (res?[key] ?? []).append(v)
  }
  return res
}

let function awardZoneCapturers(_, comp) {
  let participantAmount = comp["capzone__bombSiteParticipantsAwardAmount"]
  let planterAmount = comp["capzone__bombSitePlanterAwardAmount"]
  let plantDefenseAmount = comp["capzone__bombSiteDefenseAwardAmount"]

  let participants = comp["capzone__bombSitePlantParticipants"].getAll()
  let totalContribution = participants.reduce(@(sum, contribution) sum + contribution) ?? 0
  if (totalContribution <= 0)
    return
  let planterEid = comp["capzone__bombSitePlanterEid"]
  let participantsInfo = collectParticipantsInfo(participants)
  let invTotalContribution = participantAmount / totalContribution

  let awardList = participantsInfo.map(@(data)
    { stat = "captures", playerEid = data.playerEid, guid = data.guid, amount = data.contribution * invTotalContribution})
  let planterInfo = getSoldierInfo(planterEid)
  if (planterInfo != null)
    awardList.append(planterInfo.__merge({stat = "captures", amount = planterAmount}))

  let presence = comp["capzone__bombSiteZonePresenceOnPlant"].getAll().map(getSoldierInfo).filter(@(value) value != null)
  groupByPlayer(presence)
    .filter(@(_, player) player != planterInfo?.playerEid)
    .each(function(soldiers) {
      let soldiersCount = soldiers.len()
      let invPlayerSoldiersCount = soldiersCount > 0 ? (1.0 / soldiersCount) : 1.0
      awardList.extend(soldiers.map(@(soldier) soldier.__merge({stat="captures", amount = plantDefenseAmount * invPlayerSoldiersCount})))
    })

  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = awardList }))

  let awardedPlayers = awardList.reduce(function(res, soldier) {res[soldier?.playerEid ?? INVALID_ENTITY_ID] <- true; return res}, {})

  foreach(playerEid in awardedPlayers.keys()) {
    ecs.g_entity_mgr.sendEvent(playerEid, EventPlayerSquadHelpedToDestroyPoint())
    addAward(playerEid, "capture", {scoreId="captures"})
  }
}

ecs.register_es("award_on_bomb_site_detonation", {
  [EventAwardZoneCapturers] = awardZoneCapturers,
}, {
  comps_ro = [
    ["capzone__bombSitePlanterEid", ecs.TYPE_EID],
    ["capzone__bombSitePlantParticipants", ecs.TYPE_OBJECT],
    ["capzone__bombSiteZonePresenceOnPlant", ecs.TYPE_EID_LIST],
    ["capzone__bombSiteParticipantsAwardAmount", ecs.TYPE_FLOAT],
    ["capzone__bombSitePlanterAwardAmount", ecs.TYPE_FLOAT],
    ["capzone__bombSiteDefenseAwardAmount", ecs.TYPE_FLOAT],
  ]
}, {tags="server"})