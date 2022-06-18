options no_aot = true //since this is merely loader
module game
require ecs
require ecs.fs
require app
require ECSGlobalTags
require DagorSystem
// Common game modules, just require game.game to activate module


def private load_sound() : bool
  var ok = true
  if ecs_has_tag("soundNet") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/sound_net") && ok
  if ecs_has_tag("sound") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/sound") && ok
    ok = load_folder("%scripts/game/es/sound/vehicle") && ok
  return ok


def private load_ui() : bool
  var ok = true
  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/ui") && ok
  return ok


def private load_client() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot" // check input as real game client tag, netClient is unset on game start
    ok = load_folder("%scripts/game/es/client") && ok
    ok = load_folder("%scripts/game/es/player/client") && ok
  return ok


def private load_dedicated() : bool
  var ok = true
  if (ecs_has_tag("server") && !ecs_has_tag("gameClient")) || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/dedicated") && ok
  return ok

def private load_replay() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/replay") && ok
  return true

[init]
def load
  var ok = true
  if ecs_has_tag("dasDebug") || app::get_game_name() == "aot"
    load_optional_folder("%dngdas/das/remote/es")
    if typeinfo(builtin_module_exists EnlistedWalkerai)
      load_optional_folder("%dngdas/das/remote/es/ai")
  ok = load_sound() && ok
  ok = load_ui() && ok
  ok = load_client() && ok
  ok = load_dedicated() && ok
  ok = load_replay() && ok

  if app::get_game_name() == "aot"
    assert(ok)
