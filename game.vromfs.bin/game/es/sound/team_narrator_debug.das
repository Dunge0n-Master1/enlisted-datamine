options no_aot
require ecs
require DagorConsole
require enlisted.events_enlisted
require game.utils.team
require soundSystem
require EnlistedNet


[console_cmd(name="narrator.team")]
def team_narrator_debug_console_narrator_start()
  sound_debug("local player team id is {get_local_player_team()}")


[console_cmd(name="narrator.start")]
def team_narrator_debug_console_narrator_start(phrase : string)
  broadcastEvent([[CmdStartNarrator phrase=phrase, replace=false]])


[console_cmd(name="narrator.team_start")]
def team_narrator_debug_console_narrator_team_start(team : int; phrase : string)
  sound_debug("local player team id is {get_local_player_team()}")
  broadcast_net_event([[CmdTeamStartNarrator team=team, phrase=phrase, replace=false]])


[console_cmd(name="narrator.player_team_start")]
def team_narrator_debug_console_narrator_player_team_start(phrase : string)
  broadcast_net_event([[CmdTeamStartNarrator team=get_local_player_team(), phrase=phrase, replace=false]])


[console_cmd(name="narrator.enemy_team_start")]
def team_narrator_debug_console_narrator_enemy_team_start(phrase : string)
  let heroTeamId = get_local_player_team()
  find_query() <| $ [es] (team__id : int)
    if team__id != heroTeamId && team__id != TEAM_UNASSIGNED
      broadcast_net_event([[CmdTeamStartNarrator team=team__id, phrase=phrase, replace=false]])
      return true
    return false
