
//THIS FILE CREATED BY CODEGEN, DON'T CHANGE THIS!!! USE setup_dng_libs.bat INSTEAD!!!


options no_aot = true
require danetlibs.pathfinder.pathfinder_init
require danetlibs.verify_ecs.verify_ecs_init
require danetlibs.sound.sound_utils.sound_utils_init
require danetlibs.sound.sound_utils_net.sound_utils_net_init
require danetlibs.sound.common_sounds.common_sounds_init
require danetlibs.sound.environment_sounds.environment_sounds_init
require danetlibs.sound.door_sounds.door_sounds_init
require danetlibs.sound.human_sounds.human_sounds_init
require danetlibs.sound.human_sounds_net.human_sounds_net_init
require danetlibs.sound.vehicle_sounds.vehicle_sounds_init
require danetlibs.sound.vehicle_sounds_net.vehicle_sounds_net_init
require danetlibs.sound.ship_sounds.ship_sounds_init
require danetlibs.sound.plane_sounds.plane_sounds_init
require danetlibs.render_debug.render_debug_init
require danetlibs.route_prober.route_prober_init
require danetlibs.wounds.wounds_init
require danetlibs.imgui_daeditor.imgui_daeditor_init
require danetlibs.hero_cockpit.hero_cockpit_init
require danetlibs.console_commands.console_commands_init
require danetlibs.native_dasevents.native_dasevents_init
require danetlibs.motion_matching.motion_matching_init
require danetlibs.blood_decals.blood_decals_init
require danetlibs.frame_graph_renderer.frame_graph_renderer_init
require danetlibs.assets_import.assets_import_init
require danetlibs.light_flicker.light_flicker_init
require danetlibs.node_collapser.node_collapser_init
require danetlibs.flash_blind.flash_blind_init

def load_dng_libs() : bool
  var ok = true
  ok = load_pathfinder("%danetlibs/pathfinder") && ok
  ok = load_verify_ecs("%danetlibs/verify_ecs") && ok
  ok = load_sound_utils("%danetlibs/sound/sound_utils") && ok
  ok = load_sound_utils_net("%danetlibs/sound/sound_utils_net") && ok
  ok = load_common_sounds("%danetlibs/sound/common_sounds") && ok
  ok = load_environment_sounds("%danetlibs/sound/environment_sounds") && ok
  ok = load_door_sounds("%danetlibs/sound/door_sounds") && ok
  ok = load_human_sounds("%danetlibs/sound/human_sounds") && ok
  ok = load_human_sounds_net("%danetlibs/sound/human_sounds_net") && ok
  ok = load_vehicle_sounds("%danetlibs/sound/vehicle_sounds") && ok
  ok = load_vehicle_sounds_net("%danetlibs/sound/vehicle_sounds_net") && ok
  ok = load_ship_sounds("%danetlibs/sound/ship_sounds") && ok
  ok = load_plane_sounds("%danetlibs/sound/plane_sounds") && ok
  ok = load_render_debug("%danetlibs/render_debug") && ok
  ok = load_route_prober("%danetlibs/route_prober") && ok
  ok = load_wounds("%danetlibs/wounds") && ok
  ok = load_imgui_daeditor("%danetlibs/imgui_daeditor") && ok
  ok = load_hero_cockpit("%danetlibs/hero_cockpit") && ok
  ok = load_console_commands("%danetlibs/console_commands") && ok
  ok = load_native_dasevents("%danetlibs/native_dasevents") && ok
  ok = load_motion_matching("%danetlibs/motion_matching") && ok
  ok = load_blood_decals("%danetlibs/blood_decals") && ok
  ok = load_frame_graph_renderer("%danetlibs/frame_graph_renderer") && ok
  ok = load_assets_import("%danetlibs/assets_import") && ok
  ok = load_light_flicker("%danetlibs/light_flicker") && ok
  ok = load_node_collapser("%danetlibs/node_collapser") && ok
  ok = load_flash_blind("%danetlibs/flash_blind") && ok

  return ok

