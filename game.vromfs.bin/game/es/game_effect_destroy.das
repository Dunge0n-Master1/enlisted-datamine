require app
require ecs
require math.base

[es(tag=server, on_appear)]
def self_destroy_game_effect_appear(evt : Event; game_effect__timeToDestroy : float; var game_effect__destroyAt : float&)
  game_effect__destroyAt = get_sync_time() + game_effect__timeToDestroy


[es(tag=server, no_order)]
def self_destroy_game_effect(info : UpdateStageInfoAct; eid : EntityId; game_effect__destroyAt : float)
  if game_effect__destroyAt > 0.0 && info.curTime > game_effect__destroyAt
    destroyEntity(eid)

[es(tag=gameClient, on_appear)]
def client_self_destroy_game_effect_appear(evt : Event; game_effect__timeToDestroy : float; var game_effect__clientDestroyAt : float&)
  game_effect__clientDestroyAt = get_sync_time() + game_effect__timeToDestroy

[es(tag=gameClient, no_order)]
def client_self_destroy_game_effect(info : UpdateStageInfoAct; eid : EntityId; game_effect__clientDestroyAt : float)
  if game_effect__clientDestroyAt > 0.0 && info.curTime > game_effect__clientDestroyAt
    destroyEntity(eid)

[es(tag=server, on_disappear)]
def create_post_effect(evt : Event; post_effect__templateName : string; post_effect__duration : float; game_effect__attachedTo : EntityId; transform : float3x4 const?)
  createEntity(post_effect__templateName) <| $(var init : ComponentsInitializer)
    set(init, "game_effect__destroyAt", get_sync_time() + post_effect__duration)
    set(init, "game_effect__attachedTo", game_effect__attachedTo)
    set(init, "transform", get_TMatrix(game_effect__attachedTo, "transform") ?? transform ?? IDENT_TM)
