options no_aot

require app
require ecs.fs
require ECSGlobalTags

[export]
def load_motion_matching(base_path : string) : bool
  var ok = true

  if ecs_has_tag("gameClient") || app::get_game_name() == "aot"//not sure that we need motion_matching on server
    ok = load_sub_folder(base_path, "main/systems") && ok

  return ok
