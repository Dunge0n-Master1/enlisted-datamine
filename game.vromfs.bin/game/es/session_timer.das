require ecs
require game.utils.team
require enlisted.events_enlisted

[es(tag=server, no_order)]
def session_timer(info : UpdateStageInfoAct;
                  var session_timer__time_left : float&)
  if session_timer__time_left < 0.0
    return

  session_timer__time_left -= info.dt
  if session_timer__time_left < 0.0
    var maxRoundScore = 0
    var bestTeamId = TEAM_UNASSIGNED
    query() <| $ [es] (team__roundScore : int; team__id : int)
      if team__roundScore > maxRoundScore
        maxRoundScore = team__roundScore
        bestTeamId = team__id

    broadcastEvent([[EventTeamWon team=bestTeamId]])
