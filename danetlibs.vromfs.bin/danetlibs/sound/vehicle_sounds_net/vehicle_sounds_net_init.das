options no_aot

require app
require ecs.fs
require ECSGlobalTags


[export]
def load_vehicle_sounds_net(base_path : string) : bool
  var ok = true

  if ecs_has_tag("soundNet") || app::get_game_name() == "aot"
    ok = load_sub_folder(base_path, "modules") && ok
    ok = load_sub_folder(base_path, "es") && ok

  return ok


[export]
def test()
  let ok = load_vehicle_sounds_net("%danetlibs/sound/vehicle_sounds_net")
  assert(ok)
