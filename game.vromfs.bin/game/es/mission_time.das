require ecs
require app
require game.es.player_events
require enlisted.events_enlisted

[es(tag=server, REQUIRE=player, REQUIRE_NOT=playerIsBot)]
def save_first_player_connected_time(evt : EventOnPlayerConnected)
  query() <| $ [es] (var firstPlayerConnectionTime : float&)
    if firstPlayerConnectionTime < 0.0
      firstPlayerConnectionTime = get_sync_time()
      broadcastEvent([[EventFirstPlayerConnected time=firstPlayerConnectionTime]])

[es(tag=server, on_appear)]
def save_first_player_spawn_time(evt : Event; squad__ownerPlayer : EntityId)
  if !squad__ownerPlayer || has(squad__ownerPlayer, "playerIsBot")
    return
  query() <| $ [es] (var firstPlayerSpawnTime : float&)
    if firstPlayerSpawnTime < 0.0
      firstPlayerSpawnTime = get_sync_time()
      broadcastEvent([[EventFirstPlayerSpawned time=firstPlayerSpawnTime]])
