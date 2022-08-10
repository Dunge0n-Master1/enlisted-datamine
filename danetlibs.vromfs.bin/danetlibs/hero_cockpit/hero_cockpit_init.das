options no_aot

require app
require ecs.fs
require ECSGlobalTags


[export]
def load_hero_cockpit(base_path : string) : bool
  var ok = true

  if ecs_has_tag("render") || app::get_game_name() == "aot"
    ok = load_sub_folder(base_path, "render") && ok

  return ok


[export]
def test()
  let ok = load_hero_cockpit("%danetlibs/hero_cockpit")
  assert(ok)
