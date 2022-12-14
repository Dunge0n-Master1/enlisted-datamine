require common_shooter.es.player_kill_common
require common_shooter.events_common_shooter
require enlisted.game.es.enlisted_squad_common
require DagorSystem
require ecs
require EnlistedDm
require game.es.player_common
require game.es.player_events
require GameTimers
require EnlistedNet
require level

[es(tag=server, on_event=EventLevelLoaded)]
def player_respawn_after_armies_receive(evt : Event;
                                        eid : EntityId;
                                        possessed : EntityId;
                                        respawner__enabled : bool;
                                        isArmiesReceived : bool)
  if isArmiesReceived && !possessed && !respawner__enabled
    player_respawn_in_world_common(eid)

[es(tag=server, on_event=(PlayerRequestRespawnInWorld, RespawnRequestCommon))]
def player_respawn_in_world_server(evt : Event; eid : EntityId)
  player_respawn_in_world_common(eid)

[es(tag=netClient, on_event=PlayerRequestRespawnInWorld)]
def player_respawn_in_world_client(evt : Event; eid : EntityId)
  send_net_event(eid, [[RespawnRequestCommon]])

[es(tag=server, REQUIRE=player, before=event_on_client_disconnected)]
def process_disconnected_player(evt : EventOnClientDisconnected; eid : EntityId; var killEntityTimer : uint64&; possessed : EntityId;
                                connid : int)
  if connid != evt.connid
    return
  let killSquadTime : float = game_params_get_timer("keepAlivePlayerlessSquadTimeSec", 120.f)
  if killSquadTime > 0.f
    let timeoutCb <- @ <| ()
      kill_player_squad(eid)
      kill_player(eid)
    game_timer_clear(killEntityTimer)
    killEntityTimer = game_timer_set(timeoutCb, killSquadTime)
  sendEvent(possessed, [[CmdDetachAttachedGun]])
