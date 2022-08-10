options no_aot

require ecs
require ecs.fs
require app
require ECSGlobalTags


[export, unused_argument(base_path)]
def load_native_dasevents(base_path : string) : bool
  var ok = true

  ok = load_sub_folder(base_path, "main") && ok

  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_sub_folder(base_path, "ui") && ok

  return ok


[export]
def test()
  let ok = load_native_dasevents("%danetlibs/native_dasevents")
  assert(ok)
