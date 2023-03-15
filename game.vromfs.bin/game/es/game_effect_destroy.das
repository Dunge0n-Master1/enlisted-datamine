require app
require ecs
require math.base
require enlisted.events_enlisted

[es(tag=server, on_appear)]
def self_destroy_game_effect_appear(evt : Event; game_effect__timeToDestroy : float; var game_effect__destroyAt : float&)
  game_effect__destroyAt = get_sync_time() + game_effect__timeToDestroy


[es(tag=server, no_order)]
def self_destroy_game_effect(info : ParallelUpdateFrameDelayed; eid : EntityId; game_effect__destroyAt : float)
  if game_effect__destroyAt > 0.0 && info.curTime > game_effect__destroyAt
    destroyEntity(eid)

[es(tag=gameClient, on_appear)]
def client_self_destroy_game_effect_appear(evt : Event; game_effect__timeToDestroy : float; var game_effect__clientDestroyAt : float&)
  game_effect__clientDestroyAt = get_sync_time() + game_effect__timeToDestroy

[es(tag=gameClient, no_order)]
def client_self_destroy_game_effect(info : ParallelUpdateFrameDelayed; eid : EntityId; game_effect__clientDestroyAt : float)
  if game_effect__clientDestroyAt > 0.0 && info.curTime > game_effect__clientDestroyAt
    destroyEntity(eid)
