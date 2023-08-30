options no_aot = true//since this is merely loader
require ecs
require ecs.fs
require common_shooter.common_shooter
require app
require ECSGlobalTags
require DagorDataBlock
require DagorSystem

require %scripts/dng_libs_init

def private sound_override_voices_locale() : bool
  var locale = ""
  dgs_get_settings() |> datablock_get_block("sound") <| $(soundBlock)
    locale = soundBlock |> datablock_getStr("overrideVoicesLocale", "")
  return locale != ""

def private load_sound() : bool
  var ok = true

  if ecs_has_tag("sound") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/sound") && ok
    ok = load_folder("%scripts/game/es/sound/vehicle") && ok
    if sound_override_voices_locale() || app::get_game_name() == "aot"
      ok = load_das("%scripts/game/es/sound/optional/human_speech_override.das") && ok

  if ecs_has_tag("soundNet") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/sound_net") && ok
  return ok


def private load_render() : bool
  var ok = true
  if ecs_has_tag("render") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/render") && ok
  return ok



def private load_editor() : bool
  var ok = true
  if typeinfo(builtin_module_exists DagorEditor) || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/daEditor") && ok

  if (typeinfo(builtin_module_exists DagorImgui) && typeinfo(builtin_module_exists DagorEditor)) || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/imgui/daEditor") && ok

  return ok


def private load_ui() : bool
  var ok = true
  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/ui") && ok
  return ok


def private load_client() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot" // check input as real game client tag, netClient is unset on game start
    ok = load_folder("%scripts/game/es/client") && ok
    ok = load_folder("%scripts/game/es/player/client") && ok
  return ok


def private load_input() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/input") && ok
  return ok


def private load_tutorial() : bool
  var ok = true
  if app::get_game_name() == "aot" // load tutorial only on build server to verify scripts
    ok = load_folder("%scripts/tutorial") && ok
  return ok


def private load_dedicated() : bool
  var ok = true
  if (ecs_has_tag("server") && !ecs_has_tag("gameClient")) || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/dedicated") && ok
  return ok


def private load_dev() : bool
  var ok = true
  if ecs_has_tag("dev") || app::get_game_name() == "aot"
    ok = load_optional_folder("%enlisted_pkg_dev/game/es") && ok
  return ok


def private load_imgui() : bool
  var ok = true
  if typeinfo(builtin_module_exists DagorImgui) || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/imgui") && ok

  return ok


def private load_replay() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot"
    ok = load_folder("%scripts/game/es/replay") && ok
  return ok


def private load_sandbox() : bool
  var ok = true
  if get_app_offline_mode() || app::get_game_name() == "aot"
    ok = load_folder("%scripts/sandbox/es") && ok

    if ecs_has_tag("dev") && app::get_game_name() != "aot"
      return ok

    ok = load_das_with_debugcode("%scripts/sandbox/es/editor_console.das") && ok
    ok = load_das_with_debugcode("%scripts/sandbox/es/navmesh_rebuild_console.das") && ok

    ok = load_das_with_debugcode("%scripts/game/es/devmode_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/capzone_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/common_shooter/es/capzone_area_console.das") && ok
    ok = load_das_with_debugcode("%scripts/common_shooter/es/poly_battle_area_console.das") && ok
    ok = load_das_with_debugcode("%danetlibs/render_debug/render/collision_debug.das") && ok
    ok = load_das_with_debugcode("%danetlibs/render_debug/render/draw_scene_collision_debug.das") && ok

    ok = load_das_with_debugcode("%scripts/game/es/aircraft_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/client/camera_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/engineer_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/enlisted_teleport_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/hitpoints_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/squad_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/teleport_debug.das") && ok
    ok = load_das_with_debugcode("%scripts/game/es/weapon_spread_debug.das") && ok
  return ok


[init]
def load
  var ok = true
  if ecs_has_tag("dasDebug") || app::get_game_name() == "aot"
    load_optional_folder("%dngdas/das/remote/es")
    if typeinfo(builtin_module_exists DngWalkerai)
      load_optional_folder("%dngdas/das/remote/es/ai")
  load_optional_folder("%dngdas/das/debug/es")

  ok = load_folder("%scripts/game/es") && ok
  ok = load_folder("%scripts/game/es/ai") && ok
  ok = load_folder("%scripts/game/es/aircraft") && ok
  ok = load_folder("%scripts/game/es/effects") && ok
  ok = load_folder("%scripts/game/es/human") && ok
  ok = load_folder("%scripts/game/es/locks") && ok
  ok = load_folder("%scripts/game/es/player") && ok
  ok = load_folder("%scripts/game/es/stat_bq") && ok
  ok = load_folder("%scripts/game/es/vehicle") && ok
  ok = load_folder("%scripts/game/es/terraform") && ok
  ok = load_folder("%scripts/game/es/pve") && ok
  ok = load_folder("%scripts/game/es/train") && ok
  ok = load_folder("%scripts/game/es/voxel") && ok
  ok = load_editor() && ok
  ok = load_render() && ok
  ok = load_input() && ok
  ok = load_sound() && ok
  ok = load_tutorial() && ok
  ok = load_ui() && ok
  ok = load_client() && ok
  ok = load_dedicated() && ok
  ok = load_replay() && ok
  ok = load_dev() && ok
  ok = load_imgui() && ok
  ok = load_sandbox() && ok

  ok = load_dng_libs() && ok

  if app::get_game_name() == "aot"
    assert(ok)
