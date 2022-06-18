options no_aot = true//since this is merely loader
module common_shooter
require ecs
require ecs.fs
require app
require ECSGlobalTags
require DagorSystem


def private load_sound() : bool
  var ok = true
  if ecs_has_tag("soundNet") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/sound_net") && ok
  if ecs_has_tag("sound") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/sound") && ok
  return ok


def private load_input() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/input") && ok
  return ok


def private load_client() : bool
  var ok = true
  if ecs_has_tag("gameClient") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/client") && ok
  return ok

def private load_ui() : bool
  var ok = true
  if (typeinfo(builtin_module_exists DagorImgui) && typeinfo(builtin_module_exists DagorEditor)) || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/imgui/daEditor") && ok

  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/ui") && ok
  return ok

def private load_render() : bool
  var ok = true
  if ecs_has_tag("render") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/common_shooter/es/render") && ok
  return ok

[init]
def load
  var ok = true
  ok = load_folder("%scripts/common_shooter/es") && ok
  ok = load_folder("%scripts/common_shooter/es/mortar") && ok
  ok = load_folder("%scripts/common_shooter/es/ai") && ok
  ok = load_folder("%scripts/common_shooter/es/vehicle") && ok
  ok = load_folder("%scripts/common_shooter/es/human") && ok
  ok = load_folder("%scripts/common_shooter/es/weapon") && ok
  ok = load_folder("%scripts/common_shooter/es/triggers") && ok

  ok = load_sound() && ok
  ok = load_input() && ok
  ok = load_client() && ok
  ok = load_ui() && ok
  ok = load_render() && ok

  if app::get_game_name() == "aot"
    assert(ok)
