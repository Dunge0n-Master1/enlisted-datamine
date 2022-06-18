require ecs
require app
require player
require game.utils.team
require DagorSystem
require game.es.player_events
require common_shooter.events_common_shooter


def destroy_all_teammates_hearts(our_team : int)
  ecs::query() <| $ [es(REQUIRE=itemForResurrection)] (eid : EntityId; ressurectItemOwnerTeam : int)
    if our_team == ressurectItemOwnerTeam
      destroyEntity(eid)

[es(on_appear, tag=server)]
def drop_ressurect_item_es(evt : Event; eid, item__lastOwner : EntityId; var ressurectItemOwnerTeam : int&)
  let itemLastOwnerTeam = get_int(item__lastOwner, "team") ?? TEAM_UNASSIGNED
  if itemLastOwnerTeam == TEAM_UNASSIGNED
    logerr("in entity {item__lastOwner}:'{getEntityTemplateName(item__lastOwner)}' not present component 'team'")
    destroyEntity(eid)
    return
  ressurectItemOwnerTeam = itemLastOwnerTeam
  if !have_active_teammates(item__lastOwner, ressurectItemOwnerTeam)
    destroy_all_teammates_hearts(ressurectItemOwnerTeam)
    return

[es(on_appear, tag=gameClient, REQUIRE=item__isPickable)]
def remove_ressurect_item_from_world_es(evt : Event;
                                        ressurectItemOwnerTeam : int;
                                        var animchar_render__enabled : bool&;
                                        var item__isOnGround : bool&)
  let localPlayerEid = get_local_player_eid()
  let localTeam =  get_int(localPlayerEid, "team") ?? TEAM_UNASSIGNED
  if localTeam == TEAM_UNASSIGNED
    logerr("in entity {localPlayerEid}:'{getEntityTemplateName(localPlayerEid)}' not present component 'team'")
  let isFriendlyTeam = is_teams_friendly(ressurectItemOwnerTeam, localTeam)
  animchar_render__enabled = isFriendlyTeam
  item__isOnGround = isFriendlyTeam

[es(tag=server)]
def add_respawn_effect(evt : CmdPossessEntity; scoring_player__deaths : int)
  if scoring_player__deaths > 0
    ecs::query(evt.possessedEid) <| $ [es] (transform : float3x4; human_resurrect_effect__time : float; human_resurrect_effect__template, respawnReason : string)
      if respawnReason != "reviveByHeart"
        return
      createEntity(human_resurrect_effect__template) <| $(var init : ComponentsInitializer)
        set(init, "game_effect__attachedTo", evt.possessedEid)
        set(init, "duration", human_resurrect_effect__time)
        set(init, "transform", transform)
        set(init, "game_effect__destroyAt", get_sync_time() + human_resurrect_effect__time)

[es(tag=server)]
def change_chance_to_drop_resurrect_item_es(evt : CmdPossessEntity; scoring_player__deaths : int)
  if scoring_player__deaths == 0
    return
  var deathDrop = getRW_ecs_array(evt.possessedEid, "deathDrop")
  if deathDrop != null
    for it in deref(deathDrop)
      var obj = getRW_ecs_object(it)
      if obj != null && has(deref(obj), "resurrectItem")
        set(deref(obj), "chance", 0.0)
