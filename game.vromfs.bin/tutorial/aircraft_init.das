options no_aot

require app
require ecs.fs
require ECSGlobalTags

[init]
def load
  var ok = true

  if ecs_has_tag("gameClient") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/tutorial/es/aircraft") && ok
    ok = load_folder("%scripts/tutorial/es/common") && ok

  if app::get_game_name() == "aot"
    assert(ok)
