import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let {userstatsAdd} = require("%scripts/game/utils/userstats.nut")
let {get_gun_stat_type_by_props_id, DM_MELEE, DM_PROJECTILE, DM_BACKSTAB} = require("dm")
let getSoldierInfoFromCache = require("%scripts/game/es/soldier_info_cache.nut")
let {
  EventAnyEntityDied, EventPlayerSquadHelpedToDestroyPoint, EventAddPlayerAwardWithStat,
  EventPlayerSquadFinishedCapturing, EventOnPlayerWipedOutInfantrySquad
} = require("dasevents")

let playerCurrentWeaponKillStreakQuery = ecs.SqQuery("playerCurrentWeaponKillStreakQuery", {
  comps_rw=[["userstats__currentWeaponKillStreak", ecs.TYPE_OBJECT]]
})

let function resetWeaponKillStreak(playerEid) {
  playerCurrentWeaponKillStreakQuery(playerEid, @(_, comp)
    comp["userstats__currentWeaponKillStreak"] = {})
}

let function onWeaponKillStreak(weaponType, currentWeaponStreak, bestWeaponStreak) {
  let weaponTypeKey = $"best_killstreak_{weaponType}"
  let bestStreak = bestWeaponStreak?[weaponTypeKey] ?? 0
  let currentStreak = (currentWeaponStreak?[weaponTypeKey] ?? 0) + 1
  currentWeaponStreak[weaponTypeKey] <- currentStreak
  if (currentStreak > bestStreak)
    bestWeaponStreak[weaponTypeKey] <- currentStreak
}

let function checkKillWeapon(victimInfo, damageType, gunPropsId, currentWeaponStreak, bestWeaponStreak, userstats) {
  if ((victimInfo?.guid ?? "") != "") { // only human victims
    let weaponType = (damageType == DM_MELEE || damageType == DM_BACKSTAB)
      ? "melee" : get_gun_stat_type_by_props_id(gunPropsId) ?? ""
    if (weaponType != "") {
      userstatsAdd(userstats, null, $"{weaponType}_kills", null)
      onWeaponKillStreak(weaponType, currentWeaponStreak, bestWeaponStreak)
    }
  }
}

let function checkHeadshotKill(victimEid, victimInfo, damageType, collNodeId, userstats) {
  if ((victimInfo?.guid ?? "") != "") { // only human victims
    let nodeType = ecs.obsolete_dbg_get_comp_val(victimEid, "dm_parts__type")?[collNodeId]
    if (damageType == DM_PROJECTILE && nodeType == "head")
      userstatsAdd(userstats, null, "headshots", null)
  }
}

let getVehicleQuery = ecs.SqQuery("getVehicleQuery", {comps_ro=[["human_anim__vehicleSelected", ecs.TYPE_EID]]})
let getVehicleTypeQuery = ecs.SqQuery("getVehicleTypeQuery", {comps_ro=[["airplane", ecs.TYPE_TAG, null], ["isTank", ecs.TYPE_TAG, null]]})

let function checkKillsInVehicle(_victimEid, victimInfo, killerEid, userstats) {
  if ((victimInfo?.guid ?? "") != "") { // only human victims
    let vehicleEid = getVehicleQuery(killerEid, @(_, comp) comp["human_anim__vehicleSelected"]) ?? ecs.INVALID_ENTITY_ID
    getVehicleTypeQuery(vehicleEid, function(_, comp) {
      if (comp.isTank != null)
        userstatsAdd(userstats, null, "kills_using_tank", null)
      else if (comp.airplane != null)
        userstatsAdd(userstats, null, "kills_using_aircraft", null)
    })
  }
}

let getSoldierKindQuery = ecs.SqQuery("getSoldierKindQuery", {comps_ro = [["soldier__sKind", ecs.TYPE_STRING]]})

let function onKillWithSoldierKind(victimEid, victimInfo, killerEid, userstats) {
  let solderKind = getSoldierKindQuery(killerEid, @(_, c) c.soldier__sKind) ?? ""
  if (solderKind == "")
    return
  getVehicleTypeQuery(victimEid, function(_, comp) {
    if (comp.isTank)
      userstatsAdd(userstats, null, $"tank_kills_by_{solderKind}_kind", null)
    else if (comp.airplane)
      userstatsAdd(userstats, null, $"plane_kills_by_{solderKind}_kind", null)
    else if ((victimInfo?.guid ?? "") != "")
      userstatsAdd(userstats, null, $"kills_by_{solderKind}_kind", null)
  })
}

let getVictimBuiltGunOffenderQuery = ecs.SqQuery("getVictimBuiltGunOffenderQuery", {
  comps_ro = [
    ["death_desc__builtGunEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["last_offender__builtGunEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["airplane", ecs.TYPE_TAG, null],
    ["isTank", ecs.TYPE_TAG, null]
  ]
})
let function checkKillsWithBuiltGun(victimEid, _killerEid, userstats) {
  getVictimBuiltGunOffenderQuery(victimEid, function(_, comp) {
    if (comp.death_desc__builtGunEid != ecs.INVALID_ENTITY_ID)
      userstatsAdd(userstats, null, "kills_by_engineer_buildings", null)
    else if (comp.last_offender__builtGunEid != ecs.INVALID_ENTITY_ID) {
      if (comp.isTank)
        userstatsAdd(userstats, null, "tank_kills_by_engineer_buildings", null)
      else if (comp.airplane)
        userstatsAdd(userstats, null, "plane_kills_by_engineer_buildings", null)
    }
  })
}

let function onPlayerSquadKill(victimEid, killerEid, damageType, gunPropsId, collNodeId, currentWeaponStreak, bestWeaponStreak, userstats) {
  let victimInfo = getSoldierInfoFromCache(victimEid)
  checkHeadshotKill(victimEid, victimInfo, damageType, collNodeId, userstats)
  checkKillWeapon(victimInfo, damageType, gunPropsId, currentWeaponStreak, bestWeaponStreak, userstats)
  checkKillsInVehicle(victimEid, victimInfo, killerEid, userstats)
  onKillWithSoldierKind(victimEid, victimInfo, killerEid, userstats)
  checkKillsWithBuiltGun(victimEid, killerEid, userstats)
}

let playerUserstatsQuery = ecs.SqQuery("playerUserstatsQuery", {comps_rw=[["userstats", ecs.TYPE_OBJECT]], comps_no=["playerIsBot"]})
let offenderStatsQuery = ecs.SqQuery("offenderStatsQuery", {
  comps_rw=[
    ["userstats__currentWeaponKillStreak", ecs.TYPE_OBJECT],
    ["userstats__bestWeaponKillStreak", ecs.TYPE_OBJECT],
    ["userstats", ecs.TYPE_OBJECT]
  ],
  comps_no=["playerIsBot"]
})
let getTeamQuery = ecs.SqQuery("getTeamQuery", { comps_ro=[["team", ecs.TYPE_INT]] })

ecs.register_es("userstats_player_squad_kill_entity_es",
  {[EventAnyEntityDied] = function(evt, _eid, _comp) {
    let { victim, offender, damageType, gunPropsId, collNodeId } = evt

    let offenderPlayer = getSoldierInfoFromCache(offender)?.player ?? ecs.INVALID_ENTITY_ID
    if (offenderPlayer == ecs.INVALID_ENTITY_ID)
      return

    let victimTeam = getTeamQuery(victim, @(_, c) c.team) ?? TEAM_UNASSIGNED
    let killerTeam = getTeamQuery(offenderPlayer, @(_, c) c.team) ?? TEAM_UNASSIGNED

    if (victim == offender || victimTeam == TEAM_UNASSIGNED || is_teams_friendly(killerTeam, victimTeam))
      return
    offenderStatsQuery.perform(offenderPlayer, @(_eid, comp)
      onPlayerSquadKill(victim, offender, damageType, gunPropsId, collNodeId, comp["userstats__currentWeaponKillStreak"], comp["userstats__bestWeaponKillStreak"], comp.userstats))
  }}, {}, {tags="server"})

ecs.register_es("userstats_player_squad_spawn_reset_killstreak",
  {[ecs.EventEntityCreated] = @(_, comp) resetWeaponKillStreak(comp["squad__ownerPlayer"])},
  {comps_ro = [["squad__ownerPlayer", ecs.TYPE_EID]]},
  {tags = "server"})

ecs.register_es("userstats_player_squad_full_capture_es",
  {[EventPlayerSquadFinishedCapturing] = @(_, comp) userstatsAdd(comp.userstats, null, "points_captured", null) },
  {comps_rw=[["userstats", ecs.TYPE_OBJECT]]},
  {tags="server", before="send_userstats_es"})

ecs.register_es("userstats_player_squad_helped_to_destroy_point",
  {[EventPlayerSquadHelpedToDestroyPoint] = @(_, comp) userstatsAdd(comp.userstats, null, "mission_objectives_destroyed", null) },
  {comps_rw=[["userstats", ecs.TYPE_OBJECT]]},
  {tags="server", before="send_userstats_es"})

ecs.register_es("userstats_player_fortification_built_es",
  {[ecs.EventEntityCreated] = function(_, comp) {
      if (comp.dependsOnBuildingEid == ecs.INVALID_ENTITY_ID)
        playerUserstatsQuery.perform(comp.buildByPlayer, @(_eid, playerComp)
          userstatsAdd(playerComp.userstats, null, "fortification_built", null))
    }
  },
  {
    comps_ro=[
      ["buildByPlayer", ecs.TYPE_EID],
      ["dependsOnBuildingEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ],
    comps_no=["builder_preview"]},
  {tags="server", before="send_userstats_es"})

ecs.register_es("userstats_player_squad_wipeout_es",
  {[EventOnPlayerWipedOutInfantrySquad] = @(_, comp) userstatsAdd(comp.userstats, null, "infantry_squad_wipeout", null) },
  {comps_rw=[["userstats", ecs.TYPE_OBJECT]]},
  {tags="server", before="send_userstats_es"})

ecs.register_es("userstats_add_player_stat",
  {
    [EventAddPlayerAwardWithStat] = @(evt, _, comp) userstatsAdd(comp.userstats, null, evt.stat, null),
  },
  {comps_rw=[["userstats", ecs.TYPE_OBJECT]]},
  {tags="server", before="send_userstats_es"})
