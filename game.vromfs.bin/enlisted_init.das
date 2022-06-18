options no_aot = true//since this is merely loader
require game.game_init
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events

require enlisted.game.es.context_command_common
require enlisted.game.es.squad_behaviour_command_common
require app
require ecs
require DagorSystem

[init]
def load
  var ok = true
  if app::get_game_name() == "aot" || get_DAGOR_DBGLEVEL() > 0
    ok = load_das("%scripts/game/linter.das") && ok
  if app::get_game_name() == "aot"
    assert(ok)
