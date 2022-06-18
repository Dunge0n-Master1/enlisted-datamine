require ecs
require ecs.common
require game.es.events
require app

[event(unicast)]
struct CmdUpdateBattletime {}

[es(tag=server, on_event=EventEntityDestroyed, track=isAlive, REQUIRE=isAlive, before=(send_userstats_es, send_battle_result_es))]
def battletime_track_possessed_entity_components(evt : Event; possessedByPlr : EntityId)
  sendEventImmediate(possessedByPlr, [[CmdUpdateBattletime]])

[es(tag=server, on_event=(EventTeamRoundResult, CmdUpdateBattletime), track=(disconnected, possessed), before=(send_userstats_es, send_battle_result_es))]
def update_battletime_timer(evt : Event; possessed : EntityId; disconnected : bool; var scoring_player__battleTimeLastStartedAt : float&; var scoring_player__battleTime : float&)
  var activeNow = false
  if !disconnected
    query(possessed) <| $ [es] (isAlive : bool = true)// query to make sure it exists
      activeNow = isAlive
  let time = get_sync_time()
  scoring_player__battleTime += scoring_player__battleTimeLastStartedAt >= 0.0 ? time - scoring_player__battleTimeLastStartedAt : 0.0
  scoring_player__battleTimeLastStartedAt = activeNow ? time : -1.0