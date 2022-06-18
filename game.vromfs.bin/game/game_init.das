options no_aot = true//since this is merely loader
require ecs
require app
require ECSGlobalTags
require game.events_game
require game.es.player_events


def private load_ui_events() : bool
  var ok = true
  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_das("%scripts/game/es/ui/ui_events.das") && ok
  return ok


[init]
def load
  if is_compiling_macros()
    return
  var ok = true
  ok = load_ui_events() && ok
  if app::get_game_name() == "aot"
    assert(ok)
