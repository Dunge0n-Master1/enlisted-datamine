import "%dngscripts/ecs.nut" as ecs

let {TEAM_UNASSIGNED} = require("team")
let { addAward } = require("awards.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let { get_gun_stat_type_by_props_id, EventOnEntityHit, DM_MELEE, DM_BACKSTAB, DM_PROJECTILE } = require("dm")
let { EventAnyEntityDied, EventEntityDied, EventEngineerBuildingBroken } = require("dasevents")
let { EventOnLootItemUsed } = require("lootevents")
let { get_time_msec } = require("dagor.time")
let { get_sync_time } = require("net")
let math = require("math")
let getSoldierInfoFromCache = require("%scripts/game/es/soldier_info_cache.nut")

const TANK_KILL_ASSIST_TIME_SEC = 20
const ASSIST_TIME_MSEC = 15000
const ASSIST_DIST_SQ = 400
let lastDamage = {}

let getTeamQuery = ecs.SqQuery("getTeamQuery", { comps_ro=[["team", ecs.TYPE_INT]] })

let function getSoldierInfo(eid) {
  let cache = {
    team = TEAM_UNASSIGNED
    guid = ""
    player = INVALID_ENTITY_ID
  }.__update(getSoldierInfoFromCache(eid) ?? {})
  cache.team <- getTeamQuery(cache.player, @(_,c) c.team) ?? TEAM_UNASSIGNED
  return cache
}

let isValidSoldier = @(soldier) soldier.guid != "" && soldier.player != INVALID_ENTITY_ID

let getVictimInfoQuery = ecs.SqQuery("getVictimInfoQuery", {
  comps_ro = [
    ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["guid", ecs.TYPE_STRING, ""],
    ["squad_member__playerEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["statsCountAsKill", ecs.TYPE_TAG, null],
    ["vehicle", ecs.TYPE_TAG, null],
    ["airplane", ecs.TYPE_TAG, null],
    ["isTank", ecs.TYPE_TAG, null],
    ["transform", ecs.TYPE_MATRIX]
  ]
})

let queryVictimInfo = @(eid) getVictimInfoQuery(eid, @(_, comp) {
  team = comp.team,
  isStatsCountAsKill = comp.statsCountAsKill != null
  guid = comp.guid,
  player = comp["squad_member__playerEid"]
  isVehicle = comp.vehicle != null
  isPlane = comp.airplane != null
  isTank = comp.isTank != null
  pos = comp?.transform?.getcol(3)
}) ?? {}

let getVictimInfo = @(eid) {
  team = TEAM_UNASSIGNED
  isStatsCountAsKill = false
  guid = ""
  player = INVALID_ENTITY_ID
  isVehicle = false
  isPlane = false
  isTank = false
  pos = null
}.__update(queryVictimInfo(eid))

let killerLongRangeQuery = ecs.SqQuery("killerLongRangeQuery", {
  comps_ro = [
    ["awards__longRangeDist", ecs.TYPE_FLOAT],
    ["transform", ecs.TYPE_MATRIX],
  ]
})

let findSquadVehicleQuery = ecs.SqQuery("findSquadVehicleQuery", { comps_ro=[
  ["ownedBySquad", ecs.TYPE_EID],
  ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST]
] })

let findAliveSquadmemberSquadQuery = ecs.SqQuery("findAliveSquadmemberSquadQuery", {
  comps_ro=[["squad_member__squad", ecs.TYPE_EID]]
  comps_no=["deadEntity"]
})

let getSeatOwnerQuery = ecs.SqQuery("getSeatOwnerQuery", { comps_ro=[
  ["seat__ownerEid", ecs.TYPE_EID],
] })

let findVehicleOwnerQuery = ecs.SqQuery("findVehicleOwnerQuery", { comps_ro=[
  ["squad_member__squad", ecs.TYPE_EID],
  ["human_anim__vehicleSelected", ecs.TYPE_EID],
] })

let isAliveMemberOfSquad = @(eid, squad)
  findAliveSquadmemberSquadQuery(eid, @(_, comp) comp["squad_member__squad"] == squad) ?? false

let findSquadSizeQuery = ecs.SqQuery("findSquadSizeQuery", { comps_ro=[
  ["squad__numMembers", ecs.TYPE_INT],
] })

let getSquadSize = @(squad)
  findSquadSizeQuery(squad, @(_, squadComp) squadComp["squad__numMembers"]) ?? 0

let function getCrewAwardAmount(squad) {
  let squadSize = getSquadSize(squad)
  return squadSize > 1
    ? (1.0 / (squadSize - 1))
    : squadSize == 1
      ? 1.0
      : 0.0
}

let getCrewForAssist = @(offender_eid)
  findVehicleOwnerQuery(offender_eid, function(_, ownerComp) {
    let vehicleEid = ownerComp["human_anim__vehicleSelected"]
    let offenderSquad = ownerComp["squad_member__squad"]
    let squadSize = getSquadSize(offenderSquad)
    let offenderAddAmount = (squadSize == 1) ? 1.0 : 0.0 // for vehicle squad with single soldier
    let crewAmount = (squadSize > 1) ? (1.0 / (squadSize - 1)) : 0.0

    if (squadSize < 1)
      return []
    return findSquadVehicleQuery(vehicleEid, function(_, vehicleComp) {
      let vehicleSquad = vehicleComp.ownedBySquad
      if (vehicleSquad != offenderSquad || offenderSquad == INVALID_ENTITY_ID)
        return []
      return vehicleComp["vehicle_seats__seatEids"].getAll()
        .map(@(seatEid)
          getSeatOwnerQuery(seatEid, @(_, c) c["seat__ownerEid"]) ?? INVALID_ENTITY_ID)
        .filter(@(soldierEid)
          isAliveMemberOfSquad(soldierEid, vehicleSquad))
        .map(@(soldierEid) {
          eid = soldierEid,
          amount = (offender_eid == soldierEid) ? offenderAddAmount : crewAmount
        })
        .filter(@(award) award.amount > 0)
    }) ?? []
  }) ?? []


let enemyMarksQuery = ecs.SqQuery("enemyMarksQuery", {
  comps_ro=[
    ["transform", ecs.TYPE_MATRIX],
    ["userPointType", ecs.TYPE_STRING],
    ["userPointOwner", ecs.TYPE_EID],
    ["marker_enemy__ownerSoldierEid", ecs.TYPE_EID],
    ["timer__start", ecs.TYPE_FLOAT]
  ]
})

let function getAssistsForMarkers(_victimEid, victimPos, playerEid, playerTeam) {
  let res = {}
  if (victimPos != null) {
    enemyMarksQuery.perform(function (_, comp) {
      let eid = comp["userPointOwner"]
      if ((eid == playerEid) || (comp["userPointType"] != "enemy"))
        return
      let soldierEid = comp["marker_enemy__ownerSoldierEid"]
      let soldier = getSoldierInfo(soldierEid)
      if (!isValidSoldier(soldier) || !is_teams_friendly(playerTeam, soldier.team))
        return
      let markPos = comp["transform"].getcol(3)
      let createdAt = comp["timer__start"]
      if ((victimPos - markPos).lengthSq() < ASSIST_DIST_SQ && createdAt > (res?[eid]?.time ?? 0))
        res[eid] <- {soldier=soldierEid, player=soldier.player, guid=soldier.guid, time=createdAt}
    })
  }
  return res.values()
}

let gatherAssistsForKill = @(victimLastDamage, killerEid) victimLastDamage
  .filter(@(hitData) hitData.soldier != killerEid && hitData.time >= get_time_msec() - ASSIST_TIME_MSEC)
  .slice(-1)

let engineerAssistQuery = ecs.SqQuery("engineerAssistQuery", { comps_ro=[["last_offenders__engineerAssists", ecs.TYPE_OBJECT]] })
let getEngineerForOffender = @(victim, offender)
  engineerAssistQuery(victim, @(_, comp) comp["last_offenders__engineerAssists"]?[offender.tostring()])?.getAll()

let function applyVehicleKillAssist(vehicle_eid, killer_player_eid) {
  let isTank = ecs.obsolete_dbg_get_comp_val(vehicle_eid, "isTank", null) != null
  let isPlane = !isTank && ecs.obsolete_dbg_get_comp_val(vehicle_eid, "airplane", null) != null
  if (!isTank && !isPlane)
    return
  let assistType = isTank ? "tankKillAssists" : "planeKillAssists"
  let crewAssistType = isTank ? "tankKillAssistsAsCrew" : "planeKillAssistsAsCrew"
  let engineerAssistType = isTank ? "builtGunTankKillAssists" : "builtGunPlaneKillAssists"

  let assistTimeThreshold = get_sync_time() - TANK_KILL_ASSIST_TIME_SEC
  let vehicleOffenders = (ecs.obsolete_dbg_get_comp_val(vehicle_eid, "vehicleOffenders")?.getAll() ?? {})
    .filter(@(assist, _soldierEid)
      assist.time >= assistTimeThreshold &&
      assist.player != killer_player_eid)
    .map(@(assist, soldierEid) assist.__merge({eid=soldierEid}))
    .values()

  let soloCrewAwards = vehicleOffenders
    .filter(@(assist) !assist.isCrew && getSquadSize(assist.squad) == 1)
    .map(@(assist) assist.__merge({isCrew=true}))
  vehicleOffenders.extend(soloCrewAwards)

  let awardList = vehicleOffenders.map(@(assist) {
    stat = assist.isCrew ? crewAssistType : assistType,
    guid = assist.guid,
    squadEid = assist.squad
    amount = assist.isCrew ? getCrewAwardAmount(assist.squad) : 1
  }).filter(@(award) award.amount > 0)

  let engineerAwards = vehicleOffenders
    .filter(@(assist) !assist.isCrew)
    .map(@(assist) getEngineerForOffender(vehicle_eid, assist.eid.tointeger())?.__merge({ stat = engineerAssistType }))
    .filter(@(v) v != null)

  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({list = awardList.extend(engineerAwards)}))
}

let function applyAssist(assists) {
  let awardList = assists
    .filter(@(v) (v?.player ?? INVALID_ENTITY_ID) != INVALID_ENTITY_ID && (v?.guid ?? "") != "")
    .map(@(v) { stat = "assists", guid = v.guid, playerEid = v.player })
  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({list = awardList}))
}

let function zoneRadius(comp) {
  let sphereRad = comp["sphere_zone__radius"]
  if (sphereRad != null)
    return sphereRad
  let tm = comp["transform"]
  return math.sqrt(tm.getcol(0).lengthSq() + tm.getcol(2).lengthSq()) / 2
}

let defenseZoneQuery = ecs.SqQuery("defenseZoneQuery", {
  comps_ro=[
    ["transform", ecs.TYPE_MATRIX],
    ["capzone__owningTeam", ecs.TYPE_INT],
    ["capzone__defenseRadiusAdd", ecs.TYPE_FLOAT, 0.0],
    ["capzone__attackRadiusAdd", ecs.TYPE_FLOAT, 0.0],
    ["capzone__onlyTeamCanCapture", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["capzoneTwoChains", ecs.TYPE_TAG, null],
    ["active", ecs.TYPE_BOOL, true],
    ["sphere_zone__radius", ecs.TYPE_FLOAT, null]
  ]
})

let function onEntityDied(victimEid, killerEid, gunPropsId, damageType) {
  let victim = getVictimInfo(victimEid)
  let offender = getSoldierInfo(killerEid)

  if (victimEid == killerEid || !isValidSoldier(offender) || victim.team == TEAM_UNASSIGNED || is_teams_friendly(offender.team, victim.team))
    return

  if (victim.isStatsCountAsKill) {
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
      { list = [
        { stat = "kills", playerEid = offender.player, guid = offender.guid },
      ] }))
  }

  if (isValidSoldier(victim)) {
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
      { list = [
        { stat = "kills", playerEid = offender.player, guid = offender.guid },
        { stat = "killed", playerEid = victim.player, guid = victim.guid }
      ] }))

    if (damageType == DM_MELEE || damageType == DM_BACKSTAB)
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
        { list = [
          { stat = "meleeKills", playerEid = offender.player, guid = offender.guid },
        ] }))
    let gunStatName = get_gun_stat_type_by_props_id(gunPropsId)
    if (gunStatName == "grenade")
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
        { list = [
          { stat = "grenadeKills", playerEid = offender.player, guid = offender.guid },
        ] }))
    if (damageType == DM_PROJECTILE) {
      killerLongRangeQuery(killerEid, function(_, comp) {
        let longRangeDist = comp["awards__longRangeDist"]
        let killerPos = comp.transform.getcol(3)
        if ((killerPos - victim.pos).lengthSq() > longRangeDist * longRangeDist)
          ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
            { list = [
              { stat = "longRangeKills", playerEid = offender.player, guid = offender.guid },
            ] }))
      })
    }
  }

  let kills = ecs.obsolete_dbg_get_comp_val(killerEid, "squad_member__kills")
  if (kills != null)
    ecs.obsolete_dbg_set_comp_val(killerEid, "squad_member__kills", kills + 1)

  let crewForAssist = getCrewForAssist(killerEid)
  let engineerForAssist = getEngineerForOffender(victimEid, killerEid)

  if (victim.isVehicle)
    applyVehicleKillAssist(victimEid, offender.player)

  if (victim.isPlane) {
    addAward(offender.player, "planeKill")
    let awardList = [{ stat = "planeKills", playerEid = offender.player, guid = offender.guid }]
    awardList.extend(
      crewForAssist.map(@(award) award.__merge({ stat = "crewPlaneKillAssists" }) ))
    if (engineerForAssist != null)
      awardList.append(engineerForAssist.__merge({ stat = "builtGunPlaneKills" }))
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
      { list = awardList }))
    return
  }

  let assists = []

  if (victim.isVehicle)
    assists.extend(getAssistsForMarkers(victimEid, victim.pos, offender.player, offender.team))

  if (victim.isTank) {
    addAward(offender.player, "tankKill")
    let awardList = [{ stat = "tankKills", playerEid = offender.player, guid = offender.guid }]
    awardList.extend(
      crewForAssist.map(@(award) award.__merge({ stat = "crewTankKillAssists" }) ))
    if (engineerForAssist != null)
      awardList.append(engineerForAssist.__merge({ stat = "builtGunTankKills" }))
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
      { list = awardList }))
    applyAssist(assists)
    return
  }

  assists.extend(gatherAssistsForKill(lastDamage?[victimEid] ?? [], killerEid))
  if (victimEid in lastDamage)
    delete lastDamage[victimEid]

  applyAssist(assists)

  let engineerKillAssist =
    assists.map(@(assist) getEngineerForOffender(victimEid, assist.soldier)?.__merge({stat="builtGunKillAssists"}))
    .filter(@(v) v != null)
  let engineerAwardList = engineerKillAssist
  if (engineerForAssist != null)
    engineerAwardList.append(engineerForAssist.__merge({ stat = "builtGunKills" }))

  if (engineerAwardList.len() > 0)
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
      { list = engineerAwardList } ))

  if (crewForAssist.len() > 0) {
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
      { list = crewForAssist.map(@(award) award.__merge({ stat = "crewKillAssists" }) ) }))
  }

  if (victim.pos != null) {
    let {isNearFriendlyZone = false, isNearEnemyZone = false} = defenseZoneQuery.perform(function(_eid, comp) {
      let onlyTeamCanCapture = comp["capzone__onlyTeamCanCapture"]
      let isUncapturedOneTeamZone = onlyTeamCanCapture != TEAM_UNASSIGNED && comp["capzone__owningTeam"] != onlyTeamCanCapture
      let isCapturedFriendlyZone = is_teams_friendly(comp["capzone__owningTeam"], offender.team)
      let isCapturedEnemyZone = comp["capzone__owningTeam"] != TEAM_UNASSIGNED && !isCapturedFriendlyZone
      let capzoneTwoChains = comp.capzoneTwoChains != null
      let isAttackZone = capzoneTwoChains || isCapturedEnemyZone || (isUncapturedOneTeamZone && onlyTeamCanCapture == offender.team)
      let isDefenseZone = isCapturedFriendlyZone || (isUncapturedOneTeamZone && onlyTeamCanCapture != offender.team)
      if (comp.active && (isDefenseZone || isAttackZone)) {
        let zonePos = comp["transform"].getcol(3)
        let defenseRadius = isDefenseZone ? comp["capzone__defenseRadiusAdd"] : comp["capzone__attackRadiusAdd"]
        let zoneIncreasedRadius = zoneRadius(comp) + defenseRadius
        if ((victim.pos - zonePos).lengthSq() < zoneIncreasedRadius * zoneIncreasedRadius) {
          return { isNearFriendlyZone = isDefenseZone, isNearEnemyZone = isAttackZone }
        }
      }
      return null
    }) ?? {}
    if (isNearFriendlyZone) {
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
        { list = [{ stat = "defenseKills", playerEid = offender.player, guid = offender.guid }] }))
    }
    if (isNearEnemyZone) {
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
        { list = [{ stat = "attackKills", playerEid = offender.player, guid = offender.guid }] }))
    }
  }
}

let rallyPointQuery = ecs.SqQuery("rallyPointQuery", {
  comps_ro=[
    ["buildByPlayer", ecs.TYPE_EID],
    ["builder_info__squadEid", ecs.TYPE_EID],
    ["builder_info__guid", ecs.TYPE_STRING],
  ]
})

let spawnOnSoldierBaseQuery = ecs.SqQuery("spawnOnSoldierBaseQuery", { comps_ro=[["respawnOwnerEid", ecs.TYPE_EID]] })
let spawnOnSoldierQuery = ecs.SqQuery("spawnOnSoldierQuery", {
  comps_ro=[
    ["possessedByPlr", ecs.TYPE_EID],
    ["squad_member__squad", ecs.TYPE_EID],
    ["guid", ecs.TYPE_STRING],
  ]
})

let function onSquadSpawn(_eid, comp) {
  let spawnedPlayer = comp["squad__ownerPlayer"]
  let rallyPointEid = ecs.obsolete_dbg_get_comp_val(comp["squad__respawnBaseEid"], "dependsOnBuildingEid", INVALID_ENTITY_ID)
  rallyPointQuery.perform(rallyPointEid, function(_, rallyPointComp) {
    let rallyPointOwnerPlayer = rallyPointComp["buildByPlayer"]
    if (spawnedPlayer == rallyPointOwnerPlayer)
      return
    let squadEid = rallyPointComp["builder_info__squadEid"]
    let guid = rallyPointComp["builder_info__guid"]
    let awardList = [{ stat = "builtRallyPointUses", squadEid = squadEid, guid = guid }]
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = awardList }))
  })
  spawnOnSoldierBaseQuery.perform(comp["squad__respawnBaseEid"], function(_, spawnBaseOnSoldierComp) {
    spawnOnSoldierQuery.perform(spawnBaseOnSoldierComp["respawnOwnerEid"], function(_, spawnOnSoldierComp) {
      let spawnedOnPlayerEid = spawnOnSoldierComp["possessedByPlr"]
      if (spawnedPlayer == spawnedOnPlayerEid)
        return
      let squadEid = spawnOnSoldierComp["squad_member__squad"]
      let guid = spawnOnSoldierComp["guid"]
      let awardList = [{ stat = "hostedOnSoldierSpawns", squadEid = squadEid, guid = guid }]
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = awardList }))
    })
  })
}

ecs.register_es("enlisted_kill_award_es",
  {
    [EventAnyEntityDied] = @(evt, _, __) onEntityDied(evt.victim, evt.offender, evt.gunPropsId, evt.damageType)
  },
  {},
  {tags="server"}
)

// Only one assist per kill, so we only should keep two offenders at max (killer and assistant)
// We cannot tell if offender is a killer because hitRes can show that the victim was downed but victim also may die instantly.
let function insertOffender(offendersByVictim, victimEid, offenderData) {
  if (victimEid not in offendersByVictim)
    offendersByVictim[victimEid] <- []
  let offenders = offendersByVictim[victimEid]
  if (offenders.len() < 2) {
    offenders.append(offenderData)
    return
  }
  if (offenders[1].soldier != offenderData.soldier)
    offenders[0] = offenders[1]
  offenders[1] = offenderData
}

let function onInjuredEntity(evt, _eid, _comp) {
  let victimEid = evt[0]
  let offenderEid = evt[1]
  if (victimEid == offenderEid)
    return
  let offender = getSoldierInfo(offenderEid)
  let victim = getSoldierInfo(victimEid)
  if (!isValidSoldier(offender) || is_teams_friendly(offender.team, victim.team))
    return
  insertOffender(lastDamage, victimEid, {
    soldier   = offenderEid,
    guid      = offender.guid,
    player    = offender.player,
    time      = get_time_msec()
  })
}

ecs.register_es("enlisted_last_offender_tracker_es",
  {[EventOnEntityHit] = onInjuredEntity},
  {}, {tags="server"}) // broadcast event


let function onSquadAliveChange(_eid, comp) {
  if (comp["squad__numAliveMembers"] > 0)
    return

  let playerEid = comp["squad__ownerPlayer"]
  let prevVal = ecs.obsolete_dbg_get_comp_val(playerEid, "scoring_player__squadDeaths")
  if (prevVal != null)
    ecs.obsolete_dbg_set_comp_val(playerEid, "scoring_player__squadDeaths", prevVal + 1)
}

ecs.register_es("squad_death_es", {
    onChange = onSquadAliveChange
  },
  {
    comps_track = [["squad__numAliveMembers", ecs.TYPE_INT]],
    comps_ro = [["squad__ownerPlayer", ecs.TYPE_EID]],
  },
  {tags = "server"}
)

ecs.register_es("engineer_award_es", {
    [ecs.EventEntityCreated] = onSquadSpawn
  },
  {
    comps_ro = [["squad__respawnBaseEid", ecs.TYPE_EID], ["squad__ownerPlayer", ecs.TYPE_EID]],
  },
  {tags = "server"}
)

let healTargetQuery = ecs.SqQuery("healTargetQuery", {
  comps_ro=[["squad_member__squad", ecs.TYPE_EID], ["squad_member__playerEid", ecs.TYPE_EID], ["isDowned", ecs.TYPE_BOOL]]
})
let getSquadMemberInfoQuery = ecs.SqQuery("getSquadEidQuery", {
  comps_ro=[["squad_member__squad", ecs.TYPE_EID], ["squad_member__playerEid", ecs.TYPE_EID]]
})

let playerHealAwardCooldownQuery = ecs.SqQuery("playerHealAwardCooldownQuery", {
  comps_rw=[["heal_awards__healUses", ecs.TYPE_OBJECT]],
  comps_ro=[["heal_awards__awardPerPlayerPerMinute", ecs.TYPE_INT]]
})

let function isHealAwardAvailableByLimit(uses_info, max_uses_per_minute, target_eid, cur_time) {
  let {time = 0, count = 0} = uses_info?[target_eid.tostring()] ?? {}
  return cur_time - time > 60 || count < max_uses_per_minute
}

let function increaseHealCount(uses_info, target_eid, cur_time) {
  let {time=0, count=0} = uses_info?[target_eid.tostring()]
  uses_info[target_eid.tostring()] <- (cur_time - time > 60)
    ? {time = cur_time, count = 1}
    : {time, count = count + 1}
}

let function onHealAward(healer, target_player, target_squad, stat) {
  getSquadMemberInfoQuery(healer, function(_, comp) {
    let healerSquadEid = comp.squad_member__squad
    let healerPlayer = comp.squad_member__playerEid
    if (healerSquadEid != INVALID_ENTITY_ID && healerSquadEid == target_squad)
      return
    playerHealAwardCooldownQuery(healerPlayer, function(_, cooldownComp) {
      let time = get_sync_time()
      if (!isHealAwardAvailableByLimit(cooldownComp.heal_awards__healUses, cooldownComp.heal_awards__awardPerPlayerPerMinute, target_player, time))
        return
      increaseHealCount(cooldownComp.heal_awards__healUses, target_player, time)
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = [{ stat, eid = healer }] }))
    })
  })
}

let function onReviveAward(healer, target_squad, stat) {
  let reviverSquadEid = getSquadMemberInfoQuery(healer, @(_, c) c.squad_member__squad) ?? INVALID_ENTITY_ID
  if (reviverSquadEid == INVALID_ENTITY_ID || reviverSquadEid != target_squad)
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({ list = [{ stat, eid = healer }] }))
}

ecs.register_es("revive_award_es", {
    [EventOnLootItemUsed] = @(evt, _eid, comp) healTargetQuery.perform(evt[0], function(_, targetComp) {
      if (targetComp.isDowned && comp.item__reviveAmount > 0)
        onReviveAward(comp.item__lastOwner, targetComp.squad_member__squad, "reviveAssists")
    })
  }, { comps_ro = [["item__reviveAmount", ecs.TYPE_FLOAT], ["item__lastOwner", ecs.TYPE_EID]], },
  {tags = "server"}
)
ecs.register_es("heal_award_es", {
    [EventOnLootItemUsed] = @(evt, _eid, comp) healTargetQuery.perform(evt[0], function(_, targetComp) {
      if (!targetComp.isDowned && comp.item__healAmount > 0)
        onHealAward(comp.item__lastOwner, targetComp.squad_member__playerEid, targetComp.squad_member__squad, "healAssists")
    })
  }, { comps_ro = [["item__healAmount", ecs.TYPE_FLOAT], ["item__lastOwner", ecs.TYPE_EID]], },
  {tags = "server"}
)

ecs.register_es("marker_soldier_owner_es", {
    [ecs.EventEntityCreated] = @(_eid, comp)
      comp["marker_enemy__ownerSoldierEid"] = ecs.obsolete_dbg_get_comp_val(comp["userPointOwner"], "possessed", INVALID_ENTITY_ID)
  },
  {
    comps_rw = [["marker_enemy__ownerSoldierEid", ecs.TYPE_EID]],
    comps_ro = [["userPointOwner", ecs.TYPE_EID]]
  }
)

let playerScoreSoldierDeathsQuery = ecs.SqQuery("playerScoreSoldierDeathsQuery", {comps_rw=["scoring_player__soldierDeaths"]})

ecs.register_es("count_scoring_player_soldier_deaths", {
    [EventEntityDied] = function(_eid, comp) {
      let playerEid = ecs.obsolete_dbg_get_comp_val(comp["squad_member__squad"], "squad__ownerPlayer", INVALID_ENTITY_ID)
      playerScoreSoldierDeathsQuery.perform(playerEid, @(_, playerComp) playerComp["scoring_player__soldierDeaths"] ++)
    }
  },
  {comps_ro = [["squad_member__squad", ecs.TYPE_EID]]},
  {tags = "server"}
)

ecs.register_es("squad_wipeout_award",
  {[ecs.sqEvents.EventOnPlayerWipedOutInfantrySquad] = @(eid, _) addAward(eid, "infantry_squad_wipeout") },
  {comps_rq=["player"]}, {tags = "server"})


let function onRiDestroyed(_eid, comp) {
  let offender = getSoldierInfo(comp["riOffender"])
  if (!isValidSoldier(offender) || comp["destroyable_ri__addScoreTeam"] != offender.team)
    return
  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
    { list = [
      { stat = "barrageBalloonDestructions", playerEid = offender.player, guid = offender.guid },
    ] }))
}

ecs.register_es("ri_destroyed_award",
  {[ecs.EventEntityDestroyed] = onRiDestroyed },
  {
    comps_ro=[
      ["riOffender", ecs.TYPE_EID],
      ["destroyable_ri__addScoreTeam", ecs.TYPE_INT],
    ]
  }, {tags = "server"})

let function onEngineerBuildingBroken(evt, _eid, comp) {
  let offender = getSoldierInfo(evt.offender)
  let stat = comp.building__destructionAwardStat
  let buildingTeam = comp.builder_info__team ?? comp.placeable_item__ownerTeam ?? TEAM_UNASSIGNED
  if (stat == "" || !isValidSoldier(offender) || buildingTeam == TEAM_UNASSIGNED || is_teams_friendly(offender.team, buildingTeam))
    return
  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats(
    { list = [
      { stat, playerEid = offender.player, guid = offender.guid },
    ] }))
}

ecs.register_es("engineer_building_destroyed_award",
  { [EventEngineerBuildingBroken] = onEngineerBuildingBroken },
  {
    comps_ro = [
      ["builder_info__team", ecs.TYPE_INT, null],
      ["placeable_item__ownerTeam", ecs.TYPE_INT, null],
      ["building__destructionAwardStat", ecs.TYPE_STRING]
    ]
  }, {tags = "server"})