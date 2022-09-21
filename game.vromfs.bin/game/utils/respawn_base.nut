import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let rndInstance = require("%sqstd/rand.nut")()
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let {get_sync_time} = require("net")
let {logerr} = require("dagor.debug")
let dagorMath = require("dagor.math")
let {get_team_eid} = require("%dngscripts/common_queries.nut")

let baseQueryComps = {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["active", ecs.TYPE_BOOL],
    ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["temporaryRespawnbase", ecs.TYPE_TAG, null],
  ]
}

let respbaseWithTypeComps = baseQueryComps.__merge({
  comps_ro = [
    ["respawnbaseType", ecs.TYPE_STRING],
    ["respawnbaseSubtype", ecs.TYPE_STRING, ""]
  ].extend(baseQueryComps.comps_ro)
})

let respbaseQueryComps = baseQueryComps.__merge({
  comps_ro = [].extend(baseQueryComps.comps_ro).append(["lastSpawnOnTime", ecs.TYPE_FLOAT, -11.0]).append(["enemyReuseDelay", ecs.TYPE_FLOAT, 10.0])
  comps_rq = ["respbase"]
  comps_no = ["vehicleRespbase"]
})

let vehicleRespbaseQueryComps = baseQueryComps.__merge({
  comps_rq = ["vehicleRespbase"]
})

let respbaseWithTypeQuery = ecs.SqQuery("respbaseWithTypeQuery", respbaseWithTypeComps)
let respbaseQuery = ecs.SqQuery("respbaseQuery", respbaseQueryComps)
let vehicleRespbaseQuery = ecs.SqQuery("vehicleRespbaseQuery", vehicleRespbaseQueryComps)
let searchSafestQuery = ecs.SqQuery("searchSafestQuery", {comps_ro = [ ["isAlive", ecs.TYPE_BOOL], ["team", ecs.TYPE_INT], "transform"]})

let movingZoneQuery = ecs.SqQuery("movingZoneQuery", {comps_ro = ["moving_zone__sleepingTime", "moving_zone__sourcePos", "moving_zone__sourceRadius", "moving_zone__targetPos", "moving_zone__targetRadius", "moving_zone__startEndTime"] } )

let spawnTeamTogetherQuery = ecs.SqQuery("spawnTeamTogetherQuery", {comps_ro=[["team__id", ecs.TYPE_INT],["team__spawnTeamTogether", ecs.TYPE_BOOL, true]] })

let function get_closest_dist_sq(to_pos, positions) {
  local closestDistSq = null
  foreach (pos in positions) {
    let distSq = (pos - to_pos).lengthSq()
    if (distSq < closestDistSq || closestDistSq == null)
      closestDistSq = distSq
  }
  return closestDistSq
}

local function filter_pos_by_zone(positions) {
  movingZoneQuery.perform(
    function(_eid, comp) {
      let startMoveTime = comp["moving_zone__startEndTime"].x
      let sleepTime = comp["moving_zone__sleepingTime"]
      let interpK = dagorMath.cvt(get_sync_time(), startMoveTime - sleepTime * 0.9, startMoveTime - sleepTime * 0.1, 0.9, 0.0) // 0.9 - 0.1
      let sourcePos = comp["moving_zone__sourcePos"]
      let sourceRad = comp["moving_zone__sourceRadius"]
      let targetPos = comp["moving_zone__targetPos"]
      let targetRad = comp["moving_zone__targetRadius"]
      let validCenter = sourcePos * interpK + targetPos * (1.0 - interpK)
      let validRadius = sourceRad * interpK + targetRad * (1.0 - interpK)
      positions = positions.filter(@(pos) (pos[1] - validCenter).lengthSq() < validRadius * validRadius)
    }
  )
  return positions
}

let function get_respawn_bases_impl(query, filter, filter_cb = @(...) true) {
  let respawnBases = []
  query.perform(function(eid, comp){
    if (!filter_cb(comp))
      return
    respawnBases.append([eid, comp.transform.getcol(3), comp.team])
  }, filter);
  return respawnBases
}

let function get_friendly_entities(query, team_id, filter) {
  let friendlyEntities = []
  query.perform(function(_eid, comp) {
    if (team_id != TEAM_UNASSIGNED && comp.team == team_id)
      friendlyEntities.append(comp.transform.getcol(3))
  }, filter);
  return friendlyEntities
}

let get_filter_by_team = @(team_id)
  @"and(active,or(eq(opt(team,{1}),{0}),eq(opt(team,{1}),{1})))".subst(team_id, TEAM_UNASSIGNED)

let function get_respawn_bases(query, team_id) {
  let validEntities = get_respawn_bases_impl(query, get_filter_by_team(team_id))
  if (validEntities.len() == 0) {
    logerr("No spawn bases found for team=unassigned|{0}, fallback to all available instead".subst(team_id))
    return get_respawn_bases_impl(query, null)
  }
  return validEntities
}

let is_valid_respawn_subtype = @(subtype, subtypes)
  subtypes.len() == 0 || subtypes.contains(subtype)

let get_random_respawn_base = @(arr)
  arr.len() != 0 ? arr[rndInstance.rint(0, arr.len() - 1)][0] : ecs.INVALID_ENTITY_ID

let find_respawn_base_for_team = @(team_id)
  get_random_respawn_base(get_respawn_bases(respbaseQuery, team_id))

let find_vehicle_respawn_base_for_team = @(team_id)
  get_random_respawn_base(get_respawn_bases_impl(vehicleRespbaseQuery, get_filter_by_team(team_id)))

let find_all_respawn_bases_for_team_with_type = @(team, respType, subtypes = [])
  get_respawn_bases_impl(respbaseWithTypeQuery, get_filter_by_team(team), @(comp) comp.respawnbaseType == respType && is_valid_respawn_subtype(comp.respawnbaseSubtype, subtypes))

local function find_safest_respawn_base_impl(query, team_id, validEntities, enemyEntities, spawn_team_together = true) {
  let friendlyEntities = get_friendly_entities(query, team_id, get_filter_by_team(team_id))

  searchSafestQuery(function(_eid, comp) {
    if (!is_teams_friendly(comp.team, team_id))
      enemyEntities.append(comp.transform.getcol(3))
    else
      friendlyEntities.append(comp.transform.getcol(3))
  },"and(isAlive,ne(team,{0}))".subst(TEAM_UNASSIGNED))

  if (enemyEntities.len() == 0 && friendlyEntities.len() == 0) // no enemies, no friends, choose random spawn
    return get_random_respawn_base(validEntities)

  local bestEffortBase = ecs.INVALID_ENTITY_ID
  local maxEnemyDistSq = 0.0
  let acceptableBases = []
  let minEnemyDistSq = 2500.0 // 50
  let maxFriendDistSq = 10000.0 // 100
  let topDistSq = 1e6 // 1000
  if (friendlyEntities.len() < 1) // if we have no friends - limit our spawns. Otherwise - do not do this!
    validEntities = filter_pos_by_zone(validEntities)
  foreach (baseEntity in validEntities) {
    let basePos = baseEntity[1]
    let enemyDistSq = get_closest_dist_sq(basePos, enemyEntities)
    local friendDistSq = get_closest_dist_sq(basePos, friendlyEntities)

    let baseEid = baseEntity[0]
    let baseTeam = baseEntity[2]
    if (team_id != TEAM_UNASSIGNED && baseTeam == team_id) {
      friendDistSq = 0.0
      bestEffortBase = baseEid
      maxEnemyDistSq = topDistSq
    }
    let friendIsCloseEnough = spawn_team_together ? friendDistSq == null || friendDistSq < maxFriendDistSq : true
    if (enemyDistSq != null && enemyDistSq > maxEnemyDistSq) {
      bestEffortBase = baseEid
      maxEnemyDistSq = enemyDistSq
    }
    let enemyIsFarEnough = enemyDistSq == null || enemyDistSq > minEnemyDistSq
    if (friendIsCloseEnough && enemyIsFarEnough)
      acceptableBases.append(baseEid)
  }

  if (friendlyEntities.len() == 0 && bestEffortBase != ecs.INVALID_ENTITY_ID) // first spawn should try best effort
    return bestEffortBase
  if (acceptableBases.len() != 0)
    return acceptableBases[rndInstance.rint(0,acceptableBases.len()-1)]
  else if (bestEffortBase != ecs.INVALID_ENTITY_ID)
    return bestEffortBase

  return get_random_respawn_base(validEntities)
}

let function find_safest_respawn_base_for_team(team_id) {
  let validEntities = get_respawn_bases(respbaseQuery, team_id)
  if (validEntities.len() == 0)
    return ecs.INVALID_ENTITY_ID

  let curTime = get_sync_time()
  let enemyEntities = []
  respbaseQuery.perform(function(_eid, comp) {
    if (comp.lastSpawnOnTime + comp.enemyReuseDelay > curTime)
      enemyEntities.append(comp.transform.getcol(3))
  },"and(active,and(ne(opt(team,{1}),{0}),ne(opt(team,{1}),{1})))".subst(team_id, TEAM_UNASSIGNED))

  let spawnTeamTogether = spawnTeamTogetherQuery.perform(function(_eid, comp) {
    if (comp.team__id == team_id)
      return comp.team__spawnTeamTogether
    return null
  }) ?? true

  return find_safest_respawn_base_impl(respbaseQuery, team_id, validEntities, enemyEntities, spawnTeamTogether);
}

let function find_vehicle_safest_respawn_base_for_team(team_id) {
  let validEntities = get_respawn_bases(vehicleRespbaseQuery, team_id)
  return validEntities.len() == 0 ? ecs.INVALID_ENTITY_ID : find_safest_respawn_base_impl(vehicleRespbaseQuery, team_id, validEntities, []);
}

let find_vehicle_respawn_base = @(team, safest)
  safest ?
    find_vehicle_safest_respawn_base_for_team(team) :
    find_vehicle_respawn_base_for_team(team)

let find_human_respawn_base = @(team, safest)
  safest ?
    find_safest_respawn_base_for_team(team) :
    find_respawn_base_for_team(team)

let vehicleQuery = ecs.SqQuery("vehicleQuery", {
  comps_ro = [["team", ecs.TYPE_INT], ["isAlive", ecs.TYPE_BOOL], ["canUseRespawnbaseType", ecs.TYPE_STRING]]
  comps_rq = ["vehicle", "vehicleSpawnRestriction"]
})

let function count_vehicles_of_type(team, respawnbaseType) {
  local nowVehiclesOnSpawn = 0
  vehicleQuery(function(_eid, comp) {
    if (team == comp.team && comp.isAlive && comp.canUseRespawnbaseType == respawnbaseType)
      nowVehiclesOnSpawn++
  })
  return nowVehiclesOnSpawn
}

let function is_vehicle_spawn_allowed_by_limit(team, respawnbaseType) {
  let bases = find_all_respawn_bases_for_team_with_type(team, respawnbaseType)
  if (bases.len() == 0)
    return false
  let limit = ecs.obsolete_dbg_get_comp_val(bases[0][0], "maxVehicleOnSpawn", -1)
  if (limit < 0)
    return true
  let teamEid = get_team_eid(team) ?? ecs.INVALID_ENTITY_ID
  let pendingMap = ecs.obsolete_dbg_get_comp_val(teamEid, "team__spawnPending") ?? {}
  let pending = pendingMap?[respawnbaseType]?.len() ?? 0
  let existing = count_vehicles_of_type(team, respawnbaseType)
  return pending + existing < limit
}

return {
  find_human_respawn_base
  find_vehicle_respawn_base

  find_respawn_base_for_team
  find_safest_respawn_base_for_team

  get_random_respawn_base

  find_respawn_base_for_team_with_type = @(team, respType, subtypes = [])
    get_random_respawn_base(find_all_respawn_bases_for_team_with_type(team, respType, subtypes))

  find_all_respawn_bases_for_team_with_type

  count_vehicles_of_type

  is_vehicle_spawn_allowed_by_limit
}
