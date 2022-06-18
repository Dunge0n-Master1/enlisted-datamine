require ecs
require game.es.events
require DagorMath
require DagorSystem
require player
require game.utils.team
require math
require math.base
require app

[es(tag=server, on_appear)]
def respawn_bases_check_group_es(evt : Event; respawnBaseGroup : int)
  if respawnBaseGroup == -1
    logerr("respawn base has group (component respawnBaseGroup) but equal -1")

def calc_tm_for_respawn_group_icon(icon_team, icon_group, icon_type)
  var posSum : float3 = float3()
  var respawns_count = 0.0;
  ecs::query() <| $ [es(REQUIRE_NOT=aircraftRespbase)] (eid : EntityId; active : bool; team : int; respawnBaseGroup : int; transform : float3x4; respawnbaseType : string)
    if (active || has(eid, "customRespawnBase")) && team == icon_team && respawnBaseGroup == icon_group && respawnbaseType == icon_type
      respawns_count += 1.0
      posSum += transform[3]
  var tm = IDENT_TM
  if respawns_count == 0.0
    logerr("Can't find active respawns for icon group: {icon_group} type: {icon_type}")
    return tm
  tm[3] = posSum / respawns_count
  return tm

def create_respawn_icon(active, icon_group, icon_type, icon_tm, icon_team, custom_respawn)
  let iconTemplate = custom_respawn ? "respawn_point_selector" : "respawn_point_selector+auto_respawn_point_selector"
  createEntitySync(iconTemplate) <| $(var init : ComponentsInitializer)
    set(init, "respawn_icon__active", active)
    set(init, "transform", icon_tm)
    set(init, "respawn_icon__position", icon_tm[3])
    set(init, "selectedGroup", icon_group)
    set(init, "respawnIconType", icon_type)
    set(init, "team", icon_team)

def update_respawn_icon(respawn_base_group, respawn_base_type, respawn_base_team, respawn_base_by_group_active, custom_respawn)
  let isIconExist = find_query() <| $ [es] (eid : EntityId;
                                            team : int;
                                            selectedGroup : int;
                                            respawnIconType : string;
                                            var respawn_icon__active : bool&;
                                            var transform : float3x4&;
                                            var respawn_icon__position : float3&)
    if team == respawn_base_team && selectedGroup == respawn_base_group && respawnIconType == respawn_base_type
      respawn_icon__active = respawn_base_by_group_active
      if !respawn_icon__active && !custom_respawn
        destroyEntity(eid)
        return true
      transform = calc_tm_for_respawn_group_icon(team, selectedGroup, respawnIconType)
      respawn_icon__position = transform[3]
      return true
    return false
  if !isIconExist && (respawn_base_by_group_active || custom_respawn)
    let iconTm = calc_tm_for_respawn_group_icon(respawn_base_team, respawn_base_group, respawn_base_type)
    create_respawn_icon(respawn_base_by_group_active, respawn_base_group, respawn_base_type, iconTm, respawn_base_team, custom_respawn)

[es(tag=gameClient, track=respawn_icon__position, REQUIRE=autoRespawnSelector)]
def respawn_icons_update_position_es(evt : Event; respawn_icon__position : float3; var transform : float3x4&)
  transform[3] = respawn_icon__position

def has_active_respawns_by_group(respawn_team : int; respawn_group : int; respawn_type; exclude_eid = INVALID_ENTITY_ID)
  var hasActiveRespawnsByGroup = false
  hasActiveRespawnsByGroup = find_query() <| $ [es] (eid : EntityId; team : int; respawnBaseGroup : int; respawnbaseType : string; active : bool)
    if eid != exclude_eid && active && team == respawn_team && respawnBaseGroup == respawn_group && respawnbaseType == respawn_type
      return true
    return false
  return hasActiveRespawnsByGroup

[es(tag=server, track=active, on_appear,
                               on_event=EventOnChangeSpawnTeams)]
def respawn_bases_selector_group_es(evt : Event; eid : EntityId; respawnBaseGroup : int; team : int; respawnbaseType : string; active : bool)
  let isCustomRespawn = has(eid, "customRespawnBase")
  var hasActiveRespawnsByGroup = active
  if !active
    hasActiveRespawnsByGroup = has_active_respawns_by_group(team, respawnBaseGroup, respawnbaseType)
  update_respawn_icon(respawnBaseGroup, respawnbaseType, team, hasActiveRespawnsByGroup, isCustomRespawn)

[es(tag=server, on_event=(EventEntityDestroyed, EventComponentsDisappear), REQUIRE=(respawnBaseGroup, active))]
def respawn_bases_destroy_group_es(evt : Event; eid : EntityId; team : int; respawnBaseGroup : int; respawnbaseType : string)
  let respawnBaseTeam = team
  let hasActiveRespawnsByGroup = has_active_respawns_by_group(team, respawnBaseGroup, respawnbaseType, eid)
  if hasActiveRespawnsByGroup
    let isCustomRespawn = has(eid, "customRespawnBase")
    update_respawn_icon(respawnBaseGroup, respawnbaseType, team, hasActiveRespawnsByGroup, isCustomRespawn)
    return
  find_query() <| $ [es] (eid : EntityId; team : int; selectedGroup : int; respawnIconType : string)
    if team == respawnBaseTeam && selectedGroup == respawnBaseGroup && respawnIconType == respawnbaseType
      destroyEntity(eid)
      return true
    return false

[es(tag=server, on_event=EventOnChangeSpawnTeams, before=(respawn_bases_selector_group_es, custom_respawn_bases_selector_group_es))]
def respawn_bases_destroy_icons_on_spawn_team_changed_es(evt : Event)
  query() <| $ [es(REQUIRE=respawnIconType)] (eid : EntityId; var selectedGroup : int&)
    selectedGroup = -1
    destroyEntity(eid)

[es(tag=server, track=(isEnemyAtRespawn, nextSpawnActivateAtTime),
                        after=respawn_bases_selector_group_es,
                        on_appear,
                        on_event=EventOnChangeSpawnTeams)]
def custom_respawn_bases_selector_group_es(evt : Event;
                                           respawnBaseGroup : int;
                                           team : int;
                                           respawnbaseType : string;
                                           nextSpawnActivateAtTime : float;
                                           isEnemyAtRespawn : bool)
  let baseTeam = team
  let baseType = respawnbaseType
  let baseGroup = respawnBaseGroup
  var groupActivateAtTime = nextSpawnActivateAtTime
  var allGroupRespawnsNearEnemy = isEnemyAtRespawn
  query() <| $ [es] (team : int;
                     respawnBaseGroup : int;
                     respawnbaseType : string;
                     nextSpawnActivateAtTime : float;
                     isEnemyAtRespawn : bool)
    if team != baseTeam || respawnBaseGroup != baseGroup || respawnbaseType != baseType
      return
    if !isEnemyAtRespawn
      groupActivateAtTime = min(groupActivateAtTime, nextSpawnActivateAtTime)
    allGroupRespawnsNearEnemy &&= isEnemyAtRespawn

  find_query() <| $ [es] (team : int;
                          selectedGroup : int;
                          respawnIconType : string;
                          var respawn_icon__activateAtTime : float&;
                          var respawn_icon__isEnemyAtRespawn : bool&)
    if team == baseTeam && selectedGroup == respawnBaseGroup && respawnIconType == respawnbaseType
      respawn_icon__activateAtTime = groupActivateAtTime
      respawn_icon__isEnemyAtRespawn = allGroupRespawnsNearEnemy
      return true
    return false