require enlisted.events_enlisted
require game.utils.team
require game.utils.hero
require player
require ecs

[es(tag=gameClient, track=human_weap__currentGunEid, REQUIRE=(hero, human_weap__currentGunEid))]
def hero_weapon_changed_recreate_icons_es(evt : Event; eid : ecs::EntityId)
  sendEvent(eid, [[EventRecreateBuildIcons]])

[es(tag=gameClient, track=minimap__visibleForAll, on_appear, on_disappear, REQUIRE=minimap__visibleForAll)]
def visible_for_all_building_changed_es(evt : Event)
  let hero = get_controlled_hero()
  sendEvent(hero, [[EventRecreateBuildIcons]])

[es(tag=gameClient, on_appear)]
def building_create_by_hero_update_icons_es(evt : Event; buildByPlayer : ecs::EntityId)
  let engineer = get_Eid(buildByPlayer, "possessed") ?? INVALID_ENTITY_ID
  if !has(engineer, "hero")
    return
  sendEvent(engineer, [[EventRecreateBuildIcons]])

[es(on_event=(EventEntityDestroyed, EventEntityDied), tag=gameClient, REQUIRE=buildByPlayer)]
def building_destroyed_icons_es(evt : Event; eid : EntityId)
  let buildingEid = eid
  ecs::query() <| $ [es(REQUIRE=building_user_point)] (eid : ecs::EntityId; target : EntityId)
    if target == buildingEid
      destroyEntity(eid)

[es(tag=gameClient)]
def building_icons_creator_es(evt : EventRecreateBuildIcons; human_weap__currentGunEid : ecs::EntityId)
  ecs::query() <| $ [es(REQUIRE=building_user_point)] (eid : ecs::EntityId)
    destroyEntity(eid)
  let localPlayerEid = get_local_player_eid()
  ecs::query() <| $ [es] (eid : EntityId&;
                          transform : float3x4;
                          buildByPlayer : ecs::EntityId;
                          team : int = -1;
                          minimap__visibleForAll : bool = false;
                          minimap__visibleRadius : float = -1.0)
    if minimap__visibleForAll
      let localPlayerTeam = get_int(localPlayerEid, "team") ?? TEAM_UNASSIGNED
      if !is_teams_friendly(team, localPlayerTeam)
        return
    else
      if buildByPlayer != localPlayerEid || !has(human_weap__currentGunEid, "previewEid")
        return
    createEntitySync("user_building_point") <| $(var init : ComponentsInitializer)
      set(init, "transform", transform)
      set(init, "target", eid)
      set(init, "hud_marker__visible_distance", minimap__visibleRadius)