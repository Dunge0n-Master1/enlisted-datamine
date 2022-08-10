import "%dngscripts/ecs.nut" as ecs
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[SPAWN]")
let {logerr} = require("dagor.debug")
let {EventEntityDied, RequestCheckTeamSpawnDefeat} = require("dasevents")
let {DM_PROJECTILE, DM_MELEE, DM_EXPLOSION, DM_ZONE, DM_COLLISION, DM_HOLD_BREATH, DM_FIRE, DM_BACKSTAB, DM_DISCONNECTED, DM_BARBWIRE} = require("dm")

let victimSquadQuery = ecs.SqQuery("victimSquadQuery", {
  comps_ro=[
    ["isAlive", ecs.TYPE_BOOL],
    ["squad_member__squad", ecs.TYPE_EID]
  ]
})

let damageTypeName = {
  [DM_PROJECTILE]  = "projectile",
  [DM_MELEE]       = "melee",
  [DM_EXPLOSION]   = "explosion",
  [DM_ZONE]        = "zone",
  [DM_COLLISION]   = "collision",
  [DM_HOLD_BREATH] = "asphyxia",
  [DM_FIRE]        = "fire",
  [DM_DISCONNECTED]= "disconnected",
  [DM_BACKSTAB]    = "backstab",
  [DM_BARBWIRE]    = "barbwire"
}

let querySoldiersRevivePoints = ecs.SqQuery("querySoldiersRevivePoints", {
  comps_ro = [
    ["soldier_revive_points__healPerSquadmate", ecs.TYPE_ARRAY],
    ["soldier_revive_points__afterDeath", ecs.TYPE_ARRAY],
  ]
  comps_rw = [
    ["soldier_revive_points__points", ecs.TYPE_ARRAY],
  ]
})

let querySquadsRevivePoints = ecs.SqQuery("querySquadsRevivePoints", {
  comps_rw = [
    ["squads__revivePointsAfterDeath", ecs.TYPE_INT],
    ["squads__revivePointsPerSquad", ecs.TYPE_INT],
    ["squads__revivePointsList", ecs.TYPE_ARRAY],
  ]
})

let function updateReviveSquadsPointsOnSquadDeath(squadEid, playerEid) {
  querySquadsRevivePoints(playerEid, function(_, comp) {
    let revivePoints = comp["squads__revivePointsPerSquad"]

    let squadsCount = comp["squads__revivePointsList"].len()
    for (local i = 0; i < squadsCount; ++i)
      comp["squads__revivePointsList"][i] = min(comp["squads__revivePointsList"][i] + revivePoints, 100)

    debug("Heal all squads by {0}. Player: {1}".subst(revivePoints, playerEid))

    let squadIdx = ecs.obsolete_dbg_get_comp_val(squadEid, "squad__id")
    if (squadIdx >= 0 && squadIdx < squadsCount) {
      comp["squads__revivePointsList"][squadIdx] = comp["squads__revivePointsAfterDeath"]
      debug("Squad {0}({1}) is dead; Player: {2}".subst(squadIdx, squadEid, playerEid))
    }
    else
      logerr($"Squad {squadIdx} does not exist. There are only {squadsCount} squads.")

    ecs.g_entity_mgr.sendEvent(playerEid, RequestCheckTeamSpawnDefeat())
  })
}

let function onSoldierDeath(evt, eid, comp) {
  let victimEid = eid
  let { offender, damageType } = evt
  let victimSquadEid = comp.squad_member__squad
  let victimPlayerEid = comp.squad_member__playerEid
  let offenderPlayerEid = comp.hitpoints__lastOffenderPlayer

  if (!ecs.g_entity_mgr.doesEntityExist(victimSquadEid))
    return

  if (!ecs.obsolete_dbg_get_comp_val(victimSquadEid, "squad__isAlive", false))
    return

  local aliveSquadMembers = 0
  victimSquadQuery.perform(function(_eid, _copm) {
    ++aliveSquadMembers
  }, "and(eq(isAlive,true),eq(squad_member__squad,{0}:eid))".subst(victimSquadEid))

  let damageName = damageTypeName?[damageType] ?? $"{damageType}"
  debug($"Soldier is dead {victimEid} player <{victimPlayerEid}>: Damage: {damageName} Squad: {victimSquadEid}; Offender: {offender} <{offenderPlayerEid}>; Left: {aliveSquadMembers}")

  if (aliveSquadMembers == 0) {
    ecs.obsolete_dbg_set_comp_val(victimSquadEid, "squad__isAlive", false)
    updateReviveSquadsPointsOnSquadDeath(victimSquadEid, victimPlayerEid)
  }
}

let function validateSoldierRevivePoints(playerEid, squadIdx, soldierIdx, points, heal, afterDeath) {
  if (squadIdx < 0 || squadIdx >= points.len())
    logerr($"Squad {squadIdx} does not exist in soldier_revive_points.points for player {playerEid}. There are only {points.len()} squads.")
  else if (squadIdx >= heal.len())
    logerr($"Squad {squadIdx} does not exist in soldier_revive_points.healPerSquadmate for player {playerEid}. There are only {heal.len()} squads.")
  else if (soldierIdx < 0 || soldierIdx >= points[squadIdx].len())
    logerr($"soldier_revive_points.points has no respawn points for soldier {soldierIdx} in squad {squadIdx} for player {playerEid}. Total: {points[squadIdx].len()}.")
  else if (squadIdx >= afterDeath.len())
    logerr($"Squad {squadIdx} does not exist in soldier_revive_points.afterDeath for player {playerEid}. There are only {afterDeath.len()} squads.")
  else
    return true
  return false
}

let function onSoldierDeathRevivePoints(_eid, comp) {
  let victimSquadEid = comp.squad_member__squad
  let victimPlayerEid = comp.squad_member__playerEid
  let squadIdx = ecs.obsolete_dbg_get_comp_val(victimSquadEid, "squad__id")
  let soldierIdx = comp.soldier__id

  querySoldiersRevivePoints(victimPlayerEid, function(_, playerComp) {
    let revivePointsBySquad = playerComp.soldier_revive_points__points
    let healBySquad = playerComp.soldier_revive_points__healPerSquadmate
    let pointsAfterDeath = playerComp.soldier_revive_points__afterDeath

    if (!validateSoldierRevivePoints(victimPlayerEid, squadIdx, soldierIdx, revivePointsBySquad, healBySquad, pointsAfterDeath))
      return

    let revivePoints = revivePointsBySquad[squadIdx]
    let heal = healBySquad[squadIdx]

    foreach (i, curPoints in revivePoints)
      revivePoints[i] = min(curPoints + heal, 100)
    debug("Heal all soldiers by {0}. Player: {1}".subst(heal, victimPlayerEid))

    revivePoints[soldierIdx] = pointsAfterDeath[squadIdx]

    playerComp["soldier_revive_points__points"][squadIdx] = revivePoints

    local soldiersCanSpawn = false
    foreach (curPoints in revivePoints)
      if (curPoints >= 100)
        soldiersCanSpawn = true
    if (!soldiersCanSpawn)
      ecs.g_entity_mgr.sendEvent(victimPlayerEid, RequestCheckTeamSpawnDefeat())
  })
}

ecs.register_es("squad_revive_es",
  { [EventEntityDied] = onSoldierDeath },
  {
    comps_ro = [
      ["squad_member__squad", ecs.TYPE_EID],
      ["squad_member__playerEid", ecs.TYPE_EID],
      ["hitpoints__lastOffenderPlayer", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ]
  },
  { tags="server" })

ecs.register_es("soldier_revive_es",
  { [EventEntityDied] = onSoldierDeathRevivePoints },
  {
    comps_ro = [
      ["soldier__id", ecs.TYPE_INT],
      ["squad_member__squad", ecs.TYPE_EID],
      ["squad_member__playerEid", ecs.TYPE_EID],
    ]
  },
  { tags="server" })