require ecs
require game.es.player_events
require game.events_game
require EnlistedNet
require statsd

[es(tag=server)]
def player_game_finished_report_deserters(evt : EventSessionFinished)
  var deserter : int = 0
  var finished : int = 0
  query() <| $ [es(REQUIRE=player, REQUIRE_NOT=playerIsBot)] (scoring_player__isGameFinished : bool; disconnected : bool)
    if scoring_player__isGameFinished || !disconnected
      finished++
    else
      deserter++
  print("Reporting {deserter} deserters out of total {finished + deserter} human players")
  statsd_counter("game.played", finished, "finished", "yes")
  statsd_counter("game.played", deserter, "finished", "no")

[es(tag=server, REQUIRE=player, before=event_on_client_disconnected)]
def player_report_client_disconnected(evt : EventOnClientDisconnected; connid : int; scoring_player__isGameFinished : bool)
  if evt.connid != connid
    return
  if evt.cause == DisconnectionCause DC_CONNECTION_CLOSED
    statsd_counter("game.connection_closed", 1, "finished", scoring_player__isGameFinished ? "yes" : "no")
