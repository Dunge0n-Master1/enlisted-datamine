require enlisted.game.es.fortifications_build_common
require game.utils.team
require game.es.events
require ecs.common
require math.base
require math.linear
require Ballistics
require ecs
require app

[es(on_appear, tag=server, REQUIRE=team__memberEids)]
def building_respawn_update_team_es(evt : Event; eid : EntityId)
  addSubTemplate(eid, "respawn_creators_team")

[es(on_appear, tag=server, before=(respawn_bases_check_group_es, respawn_bases_selector_group_es), REQUIRE=autoSetRespawnGroup)]
def building_respawn_create_es(evt : Event;
                               team : int;
                               respawnGrouppingRadius = -1.f;
                               transform : float3x4;
                               var respawnBaseGroup aka created_respawnBaseGroup : int&)
  if respawnGrouppingRadius > 0.f
    let createdRespawnPos = transform[3]
    let createdRespawnTeam = team
    let findRespawnInRadiusSq = square(respawnGrouppingRadius)
    find_query() <| $ [es(REQUIRE=(autoSetRespawnGroup, respawnGrouppingRadius), REQUIRE_NOT=playerRespawnBase)] (transform : float3x4;
                                                                                                                  team : int;
                                                                                                                  respawnBaseGroup : int)
      if createdRespawnTeam == team && length_sq(transform[3] - createdRespawnPos) < findRespawnInRadiusSq
        created_respawnBaseGroup = respawnBaseGroup
        return true
      return false
  if respawnBaseGroup >= 0
    return
  find_query() <| $ [es] (team__id : int; var respawnCreatorId : int&)
    if team__id == team
      respawnBaseGroup = respawnCreatorId
      respawnCreatorId++
      return true
    return false

[es(tag=server, after=respawn_destroyer_on_spawns_change)]
def building_respawn_disabler_by_enemy(info : UpdateStageInfoAct;
                                       eid : EntityId;
                                       team : int;
                                       disableEnemyRadius : float;
                                       nextSpawnActivateAtTime = -1.f;
                                       enemyCheckInterval : float;
                                       transform : float3x4;
                                       projectileNearRespawn = false;
                                       var isEnemyAtRespawn : bool&;
                                       var active : bool&;
                                       var nextEnemyCheckAtTime : float&)
  if nextEnemyCheckAtTime > info.curTime || (!active && has(eid, "onlyDeactivateByEnemies"))
    return
  let respawnTeam = team
  isEnemyAtRespawn = projectileNearRespawn
  let respawnPos = transform[3]
  find_query() <| $ [es(REQUIRE=human)] (team : int; isAlive : bool; transform : float3x4)
    if !isAlive || team == TEAM_UNASSIGNED || is_teams_friendly(respawnTeam, team)
      return false
    if length_sq(transform[3] - respawnPos) < square(disableEnemyRadius)
      isEnemyAtRespawn = true
      return true
    return false
  active = nextSpawnActivateAtTime <= 0.0 && !isEnemyAtRespawn
  nextEnemyCheckAtTime = info.curTime + enemyCheckInterval

[es(on_event=(EventEntityCreated), tag=server)]
def respawn_counter_after_spawn(evt : Event;
                                squad__respawnBaseEid : EntityId)
  query(squad__respawnBaseEid) <| $ [es] (var respawnsBeforeDestroy : int&)
    respawnsBeforeDestroy--

[es(tag=server, track=respawnsBeforeDestroy)]
def respawn_destroyer_on_spawns_change(evt : Event;
                                       eid : EntityId;
                                       respawnCooldown : float;
                                       respawnsBeforeDestroy : int;
                                       dependsOnBuildingEid = INVALID_ENTITY_ID;
                                       var nextSpawnActivateAtTime : float&;
                                       var active : bool&)
  active = false
  nextSpawnActivateAtTime = get_sync_time() + respawnCooldown
  if respawnsBeforeDestroy <= 0
    destroyEntity(eid)
    if !!dependsOnBuildingEid
      destroyEntity(dependsOnBuildingEid)
    return

[es(tag=server, after=respawnsBeforeDestroy)]
def respawn_activate_after_cooldown_es(info : UpdateStageInfoAct;
                                       var nextSpawnActivateAtTime : float&;
                                       var active : bool&)
  if nextSpawnActivateAtTime <= 0.0 || nextSpawnActivateAtTime > info.curTime
    return
  active = true
  nextSpawnActivateAtTime = -1.0


[es(tag=server, before=building_respawn_disabler_by_enemy)]
def respawn_projectile_disabler_es(info : UpdateStageInfoAct;
                                   var nextProjectileCheckTime : float&;
                                   var projectileNearRespawn : bool&;
                                   projectileDisableDistance : float = 2.f;
                                   projectileDisableTime : float = 5.f;
                                   projectileCheckInterval : float = 0.1f;
                                   transform : float3x4;
                                   team : int)
  if nextProjectileCheckTime > 0.0 && nextProjectileCheckTime > info.curTime
    return
  var additiveCheckTime = 0.f
  let disableDistanceSq = square(projectileDisableDistance)
  projectileNearRespawn = false
  find_query() <| $ [es] (projectile_ballistics : ProjectileBallistics; ownerEid : EntityId)
    let ownerTeam = get_int(ownerEid, "team") ?? TEAM_UNASSIGNED
    if !is_teams_friendly(ownerTeam, team)
      let startPos = projectile_ballistics.state.pos;
      let endPos = projectile_ballistics.state.pos + projectile_ballistics.state.vel * info.dt;
      let respawnPos = transform[3]
      let distSq = distance_sq_to_seg(respawnPos, startPos, endPos);
      if distSq < disableDistanceSq
        projectileNearRespawn = true
        additiveCheckTime = projectileDisableTime
        return true
    return false
  nextProjectileCheckTime = info.curTime + projectileCheckInterval + additiveCheckTime