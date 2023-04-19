require ecs
require DngNet
require game.events_game
require enlisted.events_enlisted
require lagcatcher

[es(tag=server)]
def team_lost_send_round_result(evt : EventTeamLost; team__id : int)
  // Sending team round results can cause some lags in server code.
  // But it's not a big deal, because the game is already finished.
  // Disabling lagcather makes it ignore lags after the game is finished.
  lagcatcher_stop()
  broadcast_net_event([[EventTeamRoundResult team = team__id, isWon = (team__id != evt.team)]])

[es(tag=server)]
def team_won_send_round_result(evt : EventTeamWon; team__id : int)
  lagcatcher_stop()
  broadcast_net_event([[EventTeamRoundResult team = team__id, isWon = (team__id == evt.team)]])
