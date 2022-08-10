options no_aot
require ecs
require DagorSystem
require DagorConsole
require game.utils.team
require enlisted.events_enlisted
require EnlistedNet
require game.es.server_debug_common
require game.es.net_console_macro

def team_win(teamId : int)
  if teamId == TEAM_UNASSIGNED
    logerr("Team unassigned!")
    return
  if teamId == TEAM_SPECTATOR
    logerr("Team is spectator!")
    return
  broadcastEvent([[EventTeamWon team=teamId]])

[net_console_cmd(name="team.hero_win")]
def team_hero_win_cmd([[net_hero]] eid : EntityId)
  team_win(get_int(eid, "team") ?? TEAM_UNASSIGNED)

[net_console_cmd(name="team.win")]
def team_win_cmd(teamId : int)
  teamId |> team_win()

[console_cmd(name="team.set_score")]
def team_set_score_cmd(score : float; teamId = TEAM_UNASSIGNED)
  let team = teamId < 0 ? get_local_player_team() : teamId
  if is_server()
    find_query() <| $ [es] (team__id : int; var team__score : float&)
      if team__id == teamId
        team__score = score
        return true
      return false
  else
    exec_server_cmd("team.set_score {score} {team}")