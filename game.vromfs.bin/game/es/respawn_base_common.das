module respawn_base_common shared public

require ecs
require ecs.safe
require ecs.common
require app
require strings
require game.utils.team
require DagorRandom
require DagorSystem
require pathfinder

struct private RespawnBase
  eid : EntityId
  pos : float3
  team : int

def private get_random_eid(arr : array<EntityId> implicit)
  return length(arr) > 0 ? (arr[rnd_int(0, length(arr) - 1)]) : INVALID_ENTITY_ID

def private get_random_respawn_base(arr : array<RespawnBase> implicit)
  return length(arr) > 0 ? (arr[rnd_int(0, length(arr) - 1)]).eid : INVALID_ENTITY_ID

def find_respawn_base_for_team(team_id : int)
  var bases : array<RespawnBase>
  query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=vehicleRespbase)] (eid : EntityId;
                                                                    active : bool;
                                                                    transform : float3x4;
                                                                    team : int = TEAM_UNASSIGNED)
    if active && (team == TEAM_UNASSIGNED || team_id == team)
      bases |> emplace([[RespawnBase eid=eid, pos=transform[3], team = team]])

  if length(bases) == 0
    logerr("No spawn bases found for team=unassigned|{team_id}, fallback to all available instead")
    bases <- find_all_infantry_respawn_bases()

  return get_random_respawn_base(bases)

def find_respawn_base_for_team_with_type(team : int; resp_type : string; subtypes : array<string>; group : int = -1)
  let bases <- find_all_respawn_bases_for_team_with_type(team, resp_type, subtypes, group)
  return get_random_respawn_base(bases)

def private is_valid_respawn_subtype(subtype : string; subtypes : array<string>)
  return length(subtypes) == 0 || find_index(subtypes, subtype) >= 0

def private find_all_respawn_bases_for_team_with_type(for_team : int;
                                                      resp_type : string;
                                                      subtypes : array<string>;
                                                      group : int = -1)
  var res : array<RespawnBase>
  query() <| $ [es] (eid : EntityId;
                     active : bool;
                     transform : float3x4;
                     respawnbaseType : string;
                     respawnbaseSubtype : string = "";
                     respawnBaseGroup : int = -1;
                     team : int = TEAM_UNASSIGNED)
    if (active
        && (for_team == team || team == TEAM_UNASSIGNED)
        && respawnbaseType == resp_type
        && is_valid_respawn_subtype(respawnbaseSubtype, subtypes)
        && (group < 0 || group == respawnBaseGroup))
      res |> emplace([[RespawnBase eid=eid, pos=transform[3], team = team]])
  return <- res

def private get_closest_dist_sq(to_pos : float3; positions : array<float3>)
  var closestDistSq = -1.0
  for pos in positions
    let distSq = distance_sq(pos, to_pos)
    if distSq < closestDistSq || closestDistSq < 0.
      closestDistSq = distSq
  return closestDistSq

def private find_safest_respawn_base_impl(team_id : int;
                                          bases : array<RespawnBase>;
                                          var friendly_entities : array<float3>;
                                          var enemy_entities : array<float3>;
                                          spawn_team_together : bool = true)
  query() <| $ [es] (isAlive : bool; team : int; transform : float3x4)
    if !isAlive || team == TEAM_UNASSIGNED
      return
    elif !is_teams_friendly(team, team_id)
      enemy_entities |> push(transform[3])
    else
      friendly_entities |> push(transform[3])

  if length(enemy_entities) == 0 && length(friendly_entities) == 0 // no enemies, no friends, choose random spawn
    return get_random_respawn_base(bases)

  var bestEffortBase = INVALID_ENTITY_ID
  var maxEnemyDistSq = 0.0
  var acceptableBases : array<EntityId>
  let minEnemyDistSq = 2500.0 // 50
  let maxFriendDistSq = 10000.0 // 100
  let topDistSq = 1e6 // 1000

  for base in bases
    let basePos = base.pos
    let enemyDistSq = get_closest_dist_sq(basePos, enemy_entities)
    var friendDistSq = get_closest_dist_sq(basePos, friendly_entities)

    if team_id != TEAM_UNASSIGNED && base.team == team_id
      friendDistSq = 0.0
      bestEffortBase = base.eid
      maxEnemyDistSq = topDistSq
    let friendIsCloseEnough = spawn_team_together ? friendDistSq < maxFriendDistSq : true

    if enemyDistSq >= 0. && enemyDistSq > maxEnemyDistSq
      bestEffortBase = base.eid
      maxEnemyDistSq = enemyDistSq
    let enemyIsFarEnough = enemyDistSq < 0. || enemyDistSq > minEnemyDistSq

    if friendIsCloseEnough && enemyIsFarEnough
      acceptableBases |> push(base.eid)

  if length(friendly_entities) == 0 && !!bestEffortBase // first spawn should try best effort
    return bestEffortBase
  elif length(acceptableBases) > 0
    return acceptableBases[rnd_int(0, length(acceptableBases) - 1)]
  elif !!bestEffortBase
    return bestEffortBase

  return get_random_respawn_base(bases)

def private find_all_infantry_respawn_bases()
  var bases : array<RespawnBase>
  query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=vehicleRespbase)] (eid : EntityId;
                                                                    transform : float3x4;
                                                                    team : int = TEAM_UNASSIGNED)
    bases |> emplace([[RespawnBase eid=eid, pos=transform[3], team = team]])
  return <- bases

def find_safest_respawn_base_for_team(team_id : int)
  let curTime = get_sync_time()
  var bases : array<RespawnBase>
  var friendlyEntities : array<float3>
  var enemyEntities : array<float3>

  query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=vehicleRespbase)] (eid : EntityId;
                                                                    active : bool;
                                                                    transform : float3x4;
                                                                    team : int = TEAM_UNASSIGNED;
                                                                    lastSpawnOnTime : float = -11.0;
                                                                    enemyReuseDelay : float = 10.)
    if active
      if team == TEAM_UNASSIGNED
        bases |> emplace([[RespawnBase eid=eid, pos=transform[3], team = team]])
      elif team_id == team
        bases |> emplace([[RespawnBase eid=eid, pos=transform[3], team = team]])
        friendlyEntities |> push(transform[3])
      elif lastSpawnOnTime + enemyReuseDelay > curTime
        enemyEntities |> push(transform[3])

  if length(bases) == 0
    logerr("No spawn bases found for team=unassigned|{team_id}, fallback to all available instead")
    bases <- find_all_infantry_respawn_bases()

  if length(bases) == 0
    return INVALID_ENTITY_ID

  let spawnTeamTogether = !find_query() <| $ [es] (team__id : int; team__spawnTeamTogether : bool)
    return team__id == team_id && !team__spawnTeamTogether

  return find_safest_respawn_base_impl(team_id, bases, friendlyEntities, enemyEntities, spawnTeamTogether)


def find_human_respawn_base(team : int; safest : bool)
  return safest ? find_safest_respawn_base_for_team(team) : find_respawn_base_for_team(team)

def count_vehicles_of_type(count_team : int; respawnbase_type : string)
  var nowVehiclesOnSpawn = 0
  query() <| $ [es(REQUIRE=(vehicle, vehicleSpawnRestriction))] (team aka vehicle_team : int; isAlive : bool; canUseRespawnbaseType : string)
    if count_team == vehicle_team && isAlive && canUseRespawnbaseType == respawnbase_type
      nowVehiclesOnSpawn++
  return nowVehiclesOnSpawn

def is_vehicle_spawn_allowed_by_limit(limit_team : int; respawnbase_type : string)
  let bases <- find_all_respawn_bases_for_team_with_type(limit_team, respawnbase_type, [[array<string>]])
  if length(bases) == 0
    return false
  let limit = get_int(bases[0].eid, "maxVehicleOnSpawn") ?? -1
  if limit < 0
    return true
  var numOfVehicles = 0
  find_query() <| $ [es] (team__id : int; team__spawnPending : Object)
    if limit_team == team__id
      let pendingArray = team__spawnPending[respawnbase_type] ?as Array
      let pending = pendingArray != null ? length(*pendingArray) : 0
      let existing = count_vehicles_of_type(limit_team, respawnbase_type)
      numOfVehicles = pending + existing
      return true
    return false
  return numOfVehicles < limit

struct RespawnBaseType
  canUseRespawnbaseType : string
  canUseRespawnbaseSubtypes : array<string>

def get_can_use_respawnbase_type(templ_name : string) : RespawnBaseType
  var res : RespawnBaseType
  if empty(templ_name)
    return <- res
  var templ = getTemplateByName(templ_name)
  if templ == null
    templ = buildTemplateByName(templ_name)
  if templ == null
    logerr("Template '{templ_name}' not found in templates")
    return <- res

  res.canUseRespawnbaseType := get_string(getTemplateComponent(*templ, "canUseRespawnbaseType"), "")
  let subtypes = get_ecs_StringList(getTemplateComponent(*templ, "canUseRespawnbaseSubtypes"))
  if subtypes != null
    for subtype in *subtypes
      res.canUseRespawnbaseSubtypes |> push(string(subtype))
  return <- res

def is_respawn_at_team_side(spawn_pos : float3; zone_pos : float3; team aka spawn_team : int)
  var ourRespCount = 0.0
  var ourRespMidPos = float3()
  var enemyRespCount = 0.0
  var enemyRespMidPos = float3()
  query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=customRespawnBase)] (active : bool; team aka respawn_team : int; transform : float3x4; respawnbaseType : string)
    if !active || respawnbaseType != "human"
      return
    if spawn_team == respawn_team
      ourRespCount += 1.0
      ourRespMidPos += transform[3]
    else
      enemyRespCount += 1.0
      enemyRespMidPos += transform[3]
  if ourRespCount > 0.0 && enemyRespCount > 0.0
    ourRespMidPos *= rcp(ourRespCount)
    enemyRespMidPos *= rcp(enemyRespCount)
    let deltaToOurResps = ourRespMidPos - enemyRespMidPos
    if dot(deltaToOurResps.xz, spawn_pos.xz - zone_pos.xz) < 0.0
      return false
  return true

def check_exists_navmesh_path_from_respawn_to_capzone(respawnPointEid : EntityId; pos : float3; pos_end : float3)
  var result = 0
  query(respawnPointEid) <| $ [es] (respawn_point__cachedPaths : Point4List; respawn_point__cachedPathsPos : float3)
    if respawn_point__cachedPathsPos != pos
      return
    for cachedPath in respawn_point__cachedPaths
      if cachedPath.x == pos_end.x && cachedPath.y == pos_end.y && cachedPath.z == pos_end.z
        result = cachedPath.w < 0.0 ? -1 : 1
  if result != 0
    return result > 0

  let horzExt = 1.5
  let projExtents = float3(horzExt, FLT_MAX, horzExt)

  result = -1
  var pos1 = pos
  if project_to_nearest_navmesh_point_no_obstacles(pos1, projExtents)
    var pos2 = pos_end
    if project_to_nearest_navmesh_point_no_obstacles(pos2, projExtents)
      let extents = float3(0.5, FLT_MAX, 0.5)
      if check_path(pos1, pos2, extents, 0.5, 0.5)
        result = 1

  query(respawnPointEid) <| $ [es] (var respawn_point__cachedPaths : Point4List&; var respawn_point__cachedPathsPos : float3&)
    if respawn_point__cachedPathsPos != pos
      respawn_point__cachedPathsPos = pos
      clear(respawn_point__cachedPaths)

    let newCachedPath = float4(pos_end.x, pos_end.y, pos_end.z, result > 0 ? 1.0 : -1.0)

    let MAX_CACHED_PATHS = 4 // in case of overflow we replace closest one
    if length(respawn_point__cachedPaths) < MAX_CACHED_PATHS
      respawn_point__cachedPaths |> push(newCachedPath)
    else
      var closestIdx = 0
      var bestDistSq = FLT_MAX
      for i, cachedPath in iter_range(respawn_point__cachedPaths), respawn_point__cachedPaths
        let distSq = distance_sq(pos_end, float3(cachedPath.x, cachedPath.y, cachedPath.z))
        if distSq < bestDistSq
          closestIdx = i
          bestDistSq = distSq
      respawn_point__cachedPaths[closestIdx] = newCachedPath

  return result > 0
