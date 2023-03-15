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


def private load_sound_events() : bool
  var ok = true
  ok = load_das("%danetlibs/sound/human_sounds/modules/human_sounds_events.das") && ok
  ok = load_das("%danetlibs/sound/human_sounds_net/modules/human_sounds_net_events.das") && ok
  return ok


def private load_nut_binds() : bool
  return load_das("%scripts/game/es/respawn_base_common_quirrel.das")

[init]
def load
  var ok = true
  if app::get_game_name() == "aot" || (get_DAGOR_DBGLEVEL() > 0 && find_index(get_command_line_arguments(), "--das-no-linter") == -1)
    ok = load_das("%danetlibs/dascript_base/linter.das") && ok

  if !is_in_aot() && get_DAGOR_ADDRESS_SANITIZER() == 0 && ecs_has_tag("render") && typeinfo(builtin_module_exists network) && typeinfo(builtin_module_exists debugapi) && find_index(get_command_line_arguments(), "--das-no-debugger") == -1
    ok = load_das("%danetlibs/dascript_base/debugger_debug.das") && ok

  ok = load_nut_binds() && ok
  ok = load_ui_events() && ok
  ok = load_sound_events() && ok

  if app::get_game_name() == "aot"
    assert(ok)
