options no_aot = true//since this is merely loader
require ecs
require ecs.fs
require game.game
require common_shooter.common_shooter
require app
require ECSGlobalTags
require DagorDataBlock
require DagorSystem
require danetlibs.pathfinder.pathfinder_init
require sound_utils.sound_utils_init
require sound_utils_net.sound_utils_net_init
require common_sounds.common_sounds_init
require environment_sounds.environment_sounds_init
require vehicle_sounds.vehicle_sounds_init
require vehicle_sounds_net.vehicle_sounds_net_init
require weapon_sounds.weapon_sounds_init
require danetlibs.wounds.wounds_init
require danetlibs.render_debug.render_debug_init
require danetlibs.imgui_daeditor.imgui_daeditor_init
require danetlibs.route_prober.route_prober_init
require danetlibs.motion_matching.motion_matching_init
require danetlibs.console_commands.console_commands_init
require danetlibs.hero_cockpit.hero_cockpit_init


def private sound_override_voices_locale() : bool
  let soundBlock = dgs_get_settings() |> datablock_get_block_by_name_const("sound")
  let locale = soundBlock |> datablock_getStr("overrideVoicesLocale", "")
  return locale != ""

def private load_sound() : bool
  var ok = true
  ok = load_sound_utils_net("%danetlibs/sound/sound_utils_net") && ok
  ok = load_sound_utils("%danetlibs/sound/sound_utils") && ok
  ok = load_common_sounds("%danetlibs/sound/common_sounds") && ok
  ok = load_environment_sounds("%danetlibs/sound/environment_sounds") && ok
  ok = load_vehicle_sounds("%danetlibs/sound/vehicle_sounds") && ok
  ok = load_vehicle_sounds_net("%danetlibs/sound/vehicle_sounds_net") && ok
  ok = load_weapon_sounds("%danetlibs/sound/weapon_sounds") && ok

  if ecs_has_tag("sound") || app::get_game_name() == "aot"
    if sound_override_voices_locale() || app::get_game_name() == "aot"
      ok = load_das("%scripts/game/es/sound/optional/human_voice_override.das") && ok
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

def private load_dev() : bool
  var ok = true
  if ecs_has_tag("dev") || app::get_game_name() == "aot"
    ok = load_optional_folder("%enlisted_pkg_dev/game/es") && ok
  return ok

def private load_imgui() : bool
  var ok = true
  if typeinfo(builtin_module_exists DagorImgui) || app::get_game_name() == "aot"
    ok = load_optional_folder("%scripts/game/es/imgui") && ok

  return ok

[init]
def load
  var ok = true
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
  ok = load_editor() && ok
  ok = load_render() && ok
  ok = load_input() && ok
  ok = load_sound() && ok
  ok = load_tutorial() && ok
  ok = load_dev() && ok
  ok = load_imgui() && ok

  ok = load_pathfinder("%danetlibs/pathfinder") && ok
  ok = load_wounds("%danetlibs/wounds") && ok
  ok = load_render_debug("%danetlibs/render_debug") && ok
  ok = load_route_prober("%danetlibs/route_prober") && ok
  ok = load_imgui_daeditor("%danetlibs/imgui_daeditor") && ok
  ok = load_motion_matching("%danetlibs/motion_matching") && ok
  ok = load_console_commands("%danetlibs/console_commands") && ok
  ok = load_hero_cockpit("%danetlibs/hero_cockpit") && ok

  if app::get_game_name() == "aot"
    assert(ok)
