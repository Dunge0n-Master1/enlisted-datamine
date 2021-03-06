import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let {TEAM_UNASSIGNED} = require("team")
let debug = require("%sqstd/log.nut")().with_prefix("[SPAWN]")
let {logerr} = require("dagor.debug")
let {CmdSpawnSquad, CmdSpawnEntityForPlayer} = require("dasevents")
let {get_sync_time} = require("net")
let {get_team_eid} = require("%dngscripts/common_queries.nut")
let {spawnVehicleSquad, spawnSquad, calcBotCountInVehicleSquad} = require("%scripts/game/utils/squad_spawn.nut")
let {mkSpawnParamsByTeamEx} = require("%scripts/game/utils/spawn.nut")
let {CmdHeroLogEvent} = require("gameevents")
let { get_can_use_respawnbase_type } = require("%enlSqGlob/spawn_base.nut")
let {find_respawn_base_for_team_with_type, get_random_respawn_base,
       find_all_respawn_bases_for_team_with_type, is_vehicle_spawn_allowed_by_limit} = require("%scripts/game/utils/respawn_base.nut")
let getPrioritySpawnGroup = require("respawn_priority_auto_selector.nut")

let teamSquadQuery = ecs.SqQuery("teamSquadQuery", {
  comps_rw=[
    ["team__score",ecs.TYPE_FLOAT],
    ["team__squadsCanSpawn", ecs.TYPE_BOOL],
  ],
  comps_ro=[
    ["team__id",ecs.TYPE_INT],
    ["team__squadSpawnCost", ecs.TYPE_INT],
    ["team__memberEids", ecs.TYPE_EID_LIST],
    ["team__firstSpawnCostMul", ecs.TYPE_FLOAT],
    ["team__eachSquadMaxSpawns", ecs.TYPE_INT],
  ]
})

let teamSquadQueryPerform = @(team, cb) teamSquadQuery.perform(cb, "eq(team__id,{0})".subst(team))

let canSpawnPlayerSquads = @(team, playerSpawnCount)
  teamSquadQueryPerform(
    team,
    @(_eid, comp)
      comp["team__eachSquadMaxSpawns"] < 0 || playerSpawnCount < comp["team__eachSquadMaxSpawns"]
  )

let canSpawnTeamSquads = @(team, playerSpawnCount)
  teamSquadQueryPerform(
    team,
    @(_eid, comp) comp["team__squadsCanSpawn"] && (comp["team__eachSquadMaxSpawns"] < 0 ||
      playerSpawnCount < comp["team__eachSquadMaxSpawns"])
  )

let updateTeamScore = @(team, playerSpawnCount) teamSquadQueryPerform(team, function (_eid, comp) {
  let membersCount = comp["team__memberEids"].len().tofloat()
  if (membersCount <= 0)
    return
  local spawnCost = comp["team__squadSpawnCost"] / membersCount
  if (playerSpawnCount == 0)
    spawnCost *= comp["team__firstSpawnCostMul"]

  if (spawnCost > 0)
    comp["team__score"] = max(0, comp["team__score"] - spawnCost)
})

let function initPlayerRespawner(comp) {
  comp["respawner__enabled"] = true
  comp["respawner__respToBot"] = false
  comp["respawner__isFirstSpawn"] = true
  comp["respawner__respEndTime"] = 300 + get_sync_time() // TODO: remove magic numbers, use components
  comp["respawner__canRespawnTime"] = 10 + get_sync_time() // TODO: remove magic numbers, use components
  comp["respawner__canRespawnWaitNumber"] = -1
}

let function rejectSpawn(reason, team, playerEid, comp) {
  debug($"RejectSpawn: '{reason}' for team {team} and player {playerEid}")
  ecs.server_send_event(playerEid, ecs.event.EventOnSpawnError({reason=reason}), [ecs.obsolete_dbg_get_comp_val(playerEid, "connid", -1)])

  comp["respawner__enabled"] = true
  comp["respawner__respEndTime"] = 300 + get_sync_time() // TODO: see initPlayerRespawner
  comp["respawner__canRespawnTime"] = 10 + get_sync_time() // TODO: see initPlayerRespawner
  comp["respawner__canRespawnWaitNumber"] = -1
}

let function onSuccessfulSpawn(comp) {
  updateTeamScore(comp.team, comp["squads__spawnCount"])
  comp["squads__spawnCount"]++
  comp["squads__squadsCanSpawn"] = canSpawnPlayerSquads(comp.team, comp["squads__spawnCount"])
  if (comp["scoring_player__firstSpawnTime"] <= 0.0)
    comp["scoring_player__firstSpawnTime"] = get_sync_time()
}

let groupSpawnCb = @(team, canUseRespawnbaseType, respawnGroupId)
  get_random_respawn_base(
    find_all_respawn_bases_for_team_with_type(team, canUseRespawnbaseType)
      .filter(@(v) ecs.obsolete_dbg_get_comp_val(v[0], "respawnBaseGroup", -1) == respawnGroupId)
  )

let function spawnGroupError(template, team, eid, comp) {
  logerr($"'canUseRespawnbaseType' component is not set for {template}")
  rejectSpawn($"No respawn base for {template} by type", team, eid, comp)
  return false
}

let function avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType) {
  local getRespawnbaseForTeamCb = @(team, _safest = false)
    find_respawn_base_for_team_with_type(team, canUseRespawnbaseType)
  let respawnGroupId = ctx.respawnGroupId
  if (respawnGroupId >= 0)
    getRespawnbaseForTeamCb = @(team, _safest = false)
      groupSpawnCb(team, canUseRespawnbaseType, respawnGroupId)
  return [
    getRespawnbaseForTeamCb(ctx.team),
    @(team) mkSpawnParamsByTeamEx(team, getRespawnbaseForTeamCb)
  ]
}

let debugAllRespawnbasesQuery = ecs.SqQuery("debugAllRespawnbasesQuery", {
  comps_ro=["active", "transform", "team", "lastSpawnOnTime", "respawnbaseType", ["respTime", ecs.TYPE_INT, 0], ["maxVehicleOnSpawn", ecs.TYPE_INT, -1]]
  comps_rq=["respbase"]
})

let function debugDumpRespawnbases(ctx, canUseRespawnbaseType) {
  debugTableData(ctx)
  debug($"canUseRespawnbaseType = {canUseRespawnbaseType}")

  debugAllRespawnbasesQuery(function(eid, comp) {
    debug($"eid = {eid}")
    debugTableData(comp)
  })
}

let function trySpawnSquad(ctx, comp) {
  let eid                      = ctx.eid;
  let team                     = ctx.team;
  let squadId                  = ctx.squadId;
  let memberId                 = ctx.memberId;
  let botCount                 = ctx.botCount;
  let squadParams              = ctx.squadParams;
  let shouldValidateSpawnRules = ctx.shouldValidateSpawnRules;

  let templateName = squadParams.squad[memberId].gametemplate
  let canUseRespawnbaseType = get_can_use_respawnbase_type(templateName)
  if (canUseRespawnbaseType == null)
    return spawnGroupError(templateName, team, eid, comp)

  if (ctx.respawnGroupId < 0)
    ctx.respawnGroupId = getPrioritySpawnGroup(canUseRespawnbaseType, team)

  let [baseEid, cb] = avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType)
  squadParams.mkSpawnParamsCb <- cb
  if (baseEid == INVALID_ENTITY_ID) {
    if (ctx.respawnGroupId < 0)
      logerr($"Spawn squad [{squadId}, {memberId}] for team {team} is not possible. See log for more details.")
    else {
      debug($"Spawn squad [{squadId}, {memberId}] for team {team} for chosen group {ctx.respawnGroupId} is not possible.")
      ecs.g_entity_mgr.sendEvent(eid, CmdHeroLogEvent("group_is_no_longer_active", "respawn/group_is_no_longer_active", "", 0))
    }
    rejectSpawn("No respawn base for squad", team, eid, comp)
    debugDumpRespawnbases(ctx, canUseRespawnbaseType)
    return false
  }

  debug($"Spawn squad [{squadId}, {memberId}] for team {team} with bot's count {botCount}")

  if (!spawnSquad(squadParams)) {
    if (shouldValidateSpawnRules) {
      rejectSpawn("The squad cannot be created by unknown reason", team, eid, comp)
    }
    return false
  }

  return true
}

let teamPendingQuery = ecs.SqQuery("teamPendingQuery", {
  comps_rw = [["team__spawnPending", ecs.TYPE_OBJECT]]
})

let function onPlayerAwaitingVehicleSpawn(team, playerEid, respawnbaseType) {
  if (playerEid == INVALID_ENTITY_ID)
    return
  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  teamPendingQuery(teamEid, function(_eid, comp) {
    let pending = comp["team__spawnPending"]
    pending[respawnbaseType] <- (pending?[respawnbaseType] ?? []).append(ecs.EntityId(playerEid))
  })
}

let function onPendingVehicleSpawned(squadEid, respawnbaseType) {
  let playerEid = ecs.obsolete_dbg_get_comp_val(squadEid, "squad__ownerPlayer") ?? INVALID_ENTITY_ID
  if (playerEid == INVALID_ENTITY_ID)
    return
  let team = ecs.obsolete_dbg_get_comp_val(playerEid, "team") ?? TEAM_UNASSIGNED
  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  teamPendingQuery(teamEid, function(_eid, comp) {
    let pending = comp["team__spawnPending"]
    let index = pending?[respawnbaseType]?.indexof(playerEid, ecs.TYPE_EID)
    if (index != null) {
      pending[respawnbaseType].remove(index)
    } else {
      logerr($"Player {playerEid} was not removed from pending list:")
      debugTableData(pending.getAll())
    }
  })
}

let function trySpawnVehicleSquad(ctx, comp) {
  let eid                      = ctx.eid;
  let team                     = ctx.team;
  let squadId                  = ctx.squadId;
  let memberId                 = ctx.memberId;
  let botCount                 = ctx.botCount;
  let vehicle                  = ctx.vehicle;
  let squadParams              = ctx.squadParams;
  let shouldValidateSpawnRules = ctx.shouldValidateSpawnRules;
  let vehicleRespawnsBySquad   = ctx.vehicleRespawnsBySquad;

  let canUseRespawnbaseType = get_can_use_respawnbase_type(vehicle)
  if (canUseRespawnbaseType == null)
    return spawnGroupError(vehicle, team, eid, comp)

  if (ctx.respawnGroupId < 0)
    ctx.respawnGroupId = getPrioritySpawnGroup(canUseRespawnbaseType, team)

  let [baseEid, cb] = avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType)
  ctx.canUseRespawnbaseType <- canUseRespawnbaseType
  squadParams.mkSpawnParamsCb <- cb
  let nextSpawnOnVehicleInTime = vehicleRespawnsBySquad[squadId].nextSpawnOnVehicleInTime
  if (baseEid == INVALID_ENTITY_ID) {
    debug($"Spawn {vehicle} on base {baseEid} squad [{squadId}, {memberId}] for team {team} is not possible")
    rejectSpawn("No respawn base for vehicle", team, eid, comp)
    debugDumpRespawnbases(ctx, canUseRespawnbaseType)
    return false
  }
  if (shouldValidateSpawnRules && (!is_vehicle_spawn_allowed_by_limit(team, canUseRespawnbaseType) || nextSpawnOnVehicleInTime > get_sync_time())) {
    // In theory this situation is migh be an error (bug), but in practice no one is going to fix it anytime soon
    // (and its' kind hard to due to eventual consistency of replication) so report it as ordinary log message
    debug($"Spawn {vehicle} squad [{squadId}, {memberId}] for team {team} is forbidden by limit")
    rejectSpawn("The vehicle is not ready for this squad", team, eid, comp)
    let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
    debugTableData(ecs.obsolete_dbg_get_comp_val(teamEid, "team__spawnPending")?.getAll() ?? {})
    return false
  }

  debug($"Spawn vehicle squad [{squadId}, {memberId}] for team {team} with bot's count {botCount}")

  if (!spawnVehicleSquad(squadParams)) {
    if (shouldValidateSpawnRules) {
      rejectSpawn("The squad cannot be created by unknown reason", team, eid, comp)
    }
    return false
  }
  onPlayerAwaitingVehicleSpawn(team, squadParams.playerEid, canUseRespawnbaseType)

  return true
}

let respawnPointsQuery = ecs.SqQuery("respawnPointsQuery", {
  comps_ro=[["squads__revivePointsList", ecs.TYPE_ARRAY], ["soldier_revive_points__points", ecs.TYPE_ARRAY, []]]
})

let function validateRotationComps(squadRevivePoints, soldierRevivePoints, squadId, memberId) {
  if (squadId < 0 || squadId >= squadRevivePoints.len()) {
    logerr($"Squad {squadId} not found in squads.revivePointsList")
    debugTableData(squadRevivePoints)
  } else if (soldierRevivePoints.len() > 0 && (squadId >= soldierRevivePoints.len() || memberId >= soldierRevivePoints[squadId].len())) {
    logerr($"Member {memberId} of squad {squadId} not found in soldier_revive_points.points")
    debugTableData(soldierRevivePoints)
  } else
    return true
  return false
}

let validateSpawnRotation = @(playerEid, squadId, memberId) respawnPointsQuery.perform(playerEid, function(_, comp) {
  if (!validateRotationComps(comp["squads__revivePointsList"], comp["soldier_revive_points__points"], squadId, memberId))
    return false
  let squadRevivePoints = comp["squads__revivePointsList"][squadId]
  let soldierRevivePoints = comp["soldier_revive_points__points"]?[squadId]?[memberId] ?? 100
  return squadRevivePoints == 100 && soldierRevivePoints == 100
}) ?? true

let noBotsModeQuery = ecs.SqQuery("noBotsModeQuery", {comps_rq=["noBotsMode"]})

let isNoBotsMode = @() noBotsModeQuery.perform(@(...) true) ?? false

local function spawnSquadImpl(eid, comp, team, squadId, memberId, respawnGroupId) {
  if (team == TEAM_UNASSIGNED) {
    debug($"Cannot create player possessed entity for team {team}")
    return
  }

  let teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  debug($"Spaw team {team} squad")

  if (teamEid == INVALID_ENTITY_ID) {
    logerr($"Cannot create player possessed entity for team {team} because of teamEid is invalid")
    return
  }

  let squadParams = {
    squadId   = squadId
    memberId  = memberId
    team      = team
  }

  if (comp.armiesReceivedTime < 0.0 || (comp.armiesReceivedTime > 0 && comp.armiesReceivedTeam != team)) {
    debug($"Armies is not received yet for player {eid}, team {team}")
    comp.delayedSpawnSquad.append(squadParams)
    return
  }

  let playerSpawnCount = comp["squads__spawnCount"]

  if (!canSpawnTeamSquads(team, playerSpawnCount)) {
    debug($"Squad spawn is disabled by mission for team {team}")
    return
  }

  if (comp.isFirstSpawn) {
    debug($"The first spawn. Initialize respawner.")
    comp.isFirstSpawn = false
    initPlayerRespawner(comp)
    return
  }

  local squadInfo = comp.armies?[comp.army].squads[squadId]
  if (squadInfo == null) {
    debug($"Squad {squadId} not found. Fallback to 0 squad.")
    squadId = 0
    squadParams.squadId = 0
    squadInfo = comp.armies?[comp.army].squads[0]
  }
  let vehicle = squadInfo?.curVehicle.gametemplate
  let vehicleComps = squadInfo?.curVehicle?.comps?.getAll() ?? {}
  local squad = squadInfo?.squad.getAll() ?? []
  let squadProfileId = squadInfo?.squadId
  let squadMaxLen = squad.len()
  local botCount = isNoBotsMode() ? 0 : max(0, squadMaxLen - 1)

  // A vehicle squad is allowed to have bots even in mode without bots
  if (vehicle != null)
    botCount = calcBotCountInVehicleSquad(vehicle, squadMaxLen)

  comp["squads__botCount"] = botCount

  // Create deepcopy of native component ecs::Array
  // And slice to requested count: botCount + leader
  if (botCount == 0 && squad?[memberId] != null) {
    // Special game mode without bots. The player sees a whole squad and seletcs a squad member and spawns on it
    squad = [squad[memberId]]
    memberId = 0
    squadParams.memberId = 0
  }
  else
    squad = squad.slice(0, botCount + 1)

  let member = squad?[memberId]
  if (member == null) {
    debug($"Squad member {memberId} not found. Fallback to 0 squad member.")
    memberId = 0
    squadParams.memberId = memberId
  }

  squadParams.__update({
    playerEid = eid
    squad     = squad
    vehicle   = vehicle
    vehicleComps = vehicleComps
    squadProfileId = squadProfileId
  })

  let spawnCtx = {
    eid                      = eid
    team                     = team
    squadId                  = squadId
    memberId                 = memberId
    botCount                 = botCount
    squadParams              = squadParams
    shouldValidateSpawnRules = comp.shouldValidateSpawnRules
    respawnGroupId           = respawnGroupId
  }

  let soldierId = squad?[memberId]?.id ?? -1
  if (comp.shouldValidateSpawnRules && !validateSpawnRotation(eid, squadId, soldierId)) {
    rejectSpawn($"Spawn squad {squadId} member {soldierId} is not allowed by spawn rotation rules", team, eid, comp)
    return
  }

  if (vehicle) {
    spawnCtx.__update({
      vehicle                  = vehicle
      vehicleRespawnsBySquad   = comp.vehicleRespawnsBySquad
    })
    if (trySpawnVehicleSquad(spawnCtx, comp)) {
      comp.vehicleRespawnsBySquad[spawnCtx.squadId].lastSpawnOnVehicleAtTime = get_sync_time()
      onSuccessfulSpawn(comp);
    }
  }
  else if (trySpawnSquad(spawnCtx, comp))
    onSuccessfulSpawn(comp);
}

let comps = {
  comps_rw = [
    ["isFirstSpawn", ecs.TYPE_BOOL],
    ["squads__botCount", ecs.TYPE_INT],
    ["squads__spawnCount", ecs.TYPE_INT],
    ["squads__squadsCanSpawn", ecs.TYPE_BOOL],
    ["delayedSpawnSquad", ecs.TYPE_ARRAY],
    ["vehicleRespawnsBySquad", ecs.TYPE_ARRAY],
    ["respawner__respToBot", ecs.TYPE_BOOL],
    ["respawner__isFirstSpawn", ecs.TYPE_BOOL],
    ["respawner__respEndTime", ecs.TYPE_FLOAT],
    ["respawner__canRespawnTime", ecs.TYPE_FLOAT],
    ["respawner__canRespawnWaitNumber", ecs.TYPE_INT],
    ["respawner__enabled", ecs.TYPE_BOOL],
  ]

  comps_ro = [
    ["team", ecs.TYPE_INT],
    ["armiesReceivedTime", ecs.TYPE_FLOAT],
    ["armiesReceivedTeam", ecs.TYPE_INT],
    ["armies" ecs.TYPE_OBJECT],
    ["army", ecs.TYPE_STRING],
    ["scoring_player__firstSpawnTime", ecs.TYPE_FLOAT],
    ["shouldValidateSpawnRules", ecs.TYPE_BOOL],
  ]
}

ecs.register_es("spawn_squad_es", {
  [CmdSpawnSquad] = @(evt, eid, comp) spawnSquadImpl(eid, comp, evt.team, evt.squadId, evt.memberId, evt.respawnGroupId),
  [CmdSpawnEntityForPlayer] = @(evt, eid, comps) spawnSquadImpl(eid, comps, evt.team, 0, 0, -1)
}, comps)

ecs.register_es("pending_vehicle_spawn_es", {
    [[ecs.EventEntityCreated, ecs.EventComponentsAppear]] = @(_eid, comp) onPendingVehicleSpawned(comp.ownedBySquad, comp.canUseRespawnbaseType)
  },
  {
    comps_ro = [["ownedBySquad", ecs.TYPE_EID], ["canUseRespawnbaseType", ecs.TYPE_STRING]],
    comps_rq = ["vehicle"]
  },
  {tags = "server"}
)
