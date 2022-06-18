require game.utils.player_utils
require game.utils.team
require DagorMathUtils
require player
require ecs

[es(tag=server, track=(possessedByPlr, isInVehicle), on_appear)]
def spawn_on_squad_members_init_es(evt : Event;
                                   eid : EntityId;
                                   isInVehicle : bool;
                                   possessedByPlr : EntityId)
  let spawnOnFriendsAbilityEnabled = find_query() <| $ [es(REQUIRE=spawnOnSquadmates)] ()
    return true
  if !spawnOnFriendsAbilityEnabled
    return
  if !!possessedByPlr && !isInVehicle
    addSubTemplate(eid, "spawn_on_friends")
  elif has(eid, "spawnOnFriends")
    removeSubTemplate(eid, "spawn_on_friends")

[es(tag=server, on_event=EventEntityDied, REQUIRE=spawnOnFriends)]
def spawn_on_squad_members_die_es(evt : Event; eid : EntityId)
  removeSubTemplate(eid, "spawn_on_friends")

[es(tag=server, REQUIRE=spawnOnFriends, on_appear)]
def spawn_on_squad_members_create_base_es(evt : Event;
                                          eid : EntityId;
                                          team : int;
                                          transform : float3x4;
                                          var respawn_on_sodier__respawnBaseEid : EntityId&;
                                          respawn_on_sodier__respawnBaseTemplate : string)
  let ownerTm = transform
  respawn_on_sodier__respawnBaseEid = createEntity(respawn_on_sodier__respawnBaseTemplate) <| $(var init : ComponentsInitializer)
    set(init, "respawnOwnerEid", eid)
    set(init, "team", team)
    set(init, "transform", ownerTm)

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed, EventEntityDied), REQUIRE=spawnOnFriends)]
def spawn_on_squad_members_destroy_base_es(evt : Event;
                                           eid : EntityId)
  let ownerEid = eid
  find_query() <| $ [es] (eid, respawnOwnerEid : EntityId)
    if respawnOwnerEid == ownerEid
      destroyEntity(eid)
      return true
    return false

[es(tag=server, REQUIRE=playerRespawnBase, no_order)]
def respawn_on_friends_update_base_es(info : UpdateStageInfoAct;
                                      respawnOwnerEid : EntityId;
                                      var transform aka host_transform : float3x4&;
                                      var nextTmUpdateTime : float&;
                                      updateRespawnTmInterval = 0.1f)
  if nextTmUpdateTime > info.curTime
    return
  nextTmUpdateTime = info.curTime + updateRespawnTmInterval
  query(respawnOwnerEid) <| $ [es] (transform : float3x4)
    host_transform = transform

[es(on_appear, tag=server)]
def respawn_battlearea_adder_after_spawn(evt : Event;
                                         team : int;
                                         lastRespawnBaseEid : EntityId;
                                         var battle_areas_visitor__zonesIn : EidList)
  if has(lastRespawnBaseEid, "customRespawnBase")
    find_query() <| $ [es(REQUIRE=battle_area, REQUIRE=humanTriggerable)] (eid : EntityId;
                                                                           battle_area__team : int;
                                                                           active : bool)
      if active && (battle_area__team == TEAM_UNASSIGNED || team == TEAM_UNASSIGNED || battle_area__team == team)
        push(battle_areas_visitor__zonesIn, eid)
        return true
      return false

[es(tag=gameClient, REQUIRE=playerRespawnBase, before=spawn_zones_markers)]
def respawn_on_friends_update_icon_es(info : UpdateStageInfoAct;
                                      transform : float3x4;
                                      respawnOwnerEid : EntityId;
                                      respawnBaseGroup : int;
                                      respawnbaseType : string;
                                      team : int;
                                      var respawnIcon : EntityId&)
  let respawnTeam = team
  if !respawnIcon
    find_query() <| $ [es] (eid : EntityId; team : int; selectedGroup : int; respawnIconType : string)
      if team == respawnTeam && selectedGroup == respawnBaseGroup && respawnIconType == respawnbaseType
        respawnIcon = eid
        return true
      return false
  var spawnTm = transform
  var baseOwnerPlayerEid = INVALID_ENTITY_ID
  query(respawnOwnerEid) <| $ [es] (transform : float3x4; possessedByPlr : EntityId)
    spawnTm = transform
    baseOwnerPlayerEid = possessedByPlr

  var respawnCamDir = float3()
  find_query() <| $ [es(REQUIRE=respawnCamera)] (transform : float3x4)
    respawnCamDir = transform[2]
    return true

  let localPlayerEid = get_local_player_eid()
  query(respawnIcon) <| $ [es] (var transform : float3x4&;
                                var respawn_icon__isHidden : bool&;
                                var respawn_icon__iconIndex : int&;
                                var respawn_icon__additiveAngle : float&;
                                var respawn_icon__isPlayerSpawn : bool&)
    respawn_icon__isPlayerSpawn = true
    respawn_icon__additiveAngle = -dir_to_angles(respawnCamDir).x
    respawn_icon__isHidden = (localPlayerEid == baseOwnerPlayerEid || !is_players_in_same_group(localPlayerEid, baseOwnerPlayerEid))
    if is_players_in_same_group(localPlayerEid, baseOwnerPlayerEid)
      respawn_icon__iconIndex = (get_int(baseOwnerPlayerEid, "player_group__memberIndex") ?? 0) + 1
    transform = spawnTm
