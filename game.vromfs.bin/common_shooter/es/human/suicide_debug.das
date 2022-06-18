options no_aot
require ecs
require EnlistedNet
require DagorConsole
require game.utils.hero
require game.events_game

[console_cmd(name="player.kill")]
def player_kill_cmd()
  send_net_event(get_controlled_hero(), [[RequestSuicide]])

[console_cmd(name="player.suicide")]
def player_suicide_cmd()
  send_net_event(get_controlled_hero(), [[RequestSuicide]])
