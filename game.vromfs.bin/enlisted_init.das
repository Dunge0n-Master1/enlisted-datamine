options no_aot = true//since this is merely loader
require game.es.vehicle.vehicle_events
require game.events_game
require game.es.player_events
require enlisted.events_enlisted
require enlisted.game.es.context_command_common
require enlisted.game.es.squad_behaviour_command_common
require enlisted.game.es.terraform.terraform_common
require app
require ecs
require DagorSystem
require ECSGlobalTags


def private load_ui_events() : bool
  var ok = true
  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_das("%scripts/game/es/ui/ui_events.das") && ok
  return ok


def private load_render_events() : bool
  var ok = true
  if ecs_has_tag("render") || app::get_game_name() == "aot"
    ok = load_das("%scripts/game/es/render/render_events.das") && ok
  return ok


[init]
def load
  var ok = true
  if app::get_game_name() == "aot" || get_DAGOR_DBGLEVEL() > 0
    ok = load_das("%danetlibs/dascript_base/linter.das") && ok

  ok = load_ui_events() && ok
  ok = load_render_events() && ok

  if app::get_game_name() == "aot"
    assert(ok)
