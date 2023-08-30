from "%enlSqGlob/ui_library.nut" import *

require("%ui/_packages/common_shooter/game_console.nut")
require("%ui/hud/state/on_disconnect_server_es.nut")
require("%ui/hud/state/assists_es.nut")
require("%ui/hud/state/rumble_es.nut")
require("%ui/hud/state/gyro_only_in_aim_or_zoom.nut")
require("%ui/hud/state/preferred_plane_control_mode.nut")
require("%ui/hud/spectator_console.nut")
require("%ui/hud/state/aiming_smooth.nut")
require("%ui/hud/state/cmd_hero_log_event.nut")
require("%enlSqGlob/notifications/disconnectedControllerMsg.nut")
require("state/battle_area_warnings.nut")
require("state/team_score_warnings.nut")

require("state/autoShowBriefing.nut")
require("%enlSqGlob/ui/styleUpdate.nut")

require("state/respawnPrioritySelector.nut")
require("state/armyData.nut")
require("state/hints.nut")
require("state/goal.nut")
require("state/kill_log_es.nut")
require("%ui/hud/state/gun_blocked_es.nut")

require("hud_layout_setup.nut")
require("huds/capzone_locked_player_event.nut")
require("state/afk_warnings.nut")
require("init_tips.nut")
require("%ui/hud/state/vehicle_hp.nut")
require("%ui/hud/state/plane_hud_state.nut")
require("menus/init_game_menu_items.nut")
require("commands_menu_setup.nut")
require("building_tool_menu_setup.nut")
require("wallposter_menu_setup.nut")
require("state/dominationModeEvents.nut")
require("%enlSqGlob/ui/webHandlers/webHandlers.nut")
require("state/serviceNotificationToChat.nut")

let enlisted_loading = require("loading/enlisted_loading.nut")
let {setLoadingComp} = require("%ui/loading/loading.nut")
setLoadingComp(enlisted_loading)

require("hud_menus.nut")
let { setMenuOptions, menuTabsOrder } = require("%ui/hud/menus/settings_menu.nut")
let { violenceOptions } = require("%ui/hud/menus/options/violence_options.nut")
let { harmonizationOption } = require("%ui/hud/menus/options/harmonization_options.nut")
let planeContolOptions = require("%ui/hud/menus/options/plane_control_options.nut")
let { cameraShakeOptions } = require("%ui/hud/menus/options/camera_shake_options.nut")
let { hudOptions } = require("%ui/hud/menus/options/hud_options.nut")
let { renderOptions } = require("%ui/hud/menus/options/render_options.nut")
let { soundOptions } = require("%ui/hud/menus/options/sound_options.nut")
let { cameraFovOption } = require("%ui/hud/menus/options/camera_fov_option.nut")
let { vehicleCameraFovOption } = require("%ui/hud/menus/vehicle_camera_fov_option.nut")
let { vehicleCameraFollowOption } = require("%ui/hud/menus/vehicle_camera_follow_option.nut")
let { voiceChatOptions } = require("%ui/hud/menus/options/voicechat_options.nut")
let narratorOptions = require("%ui/hud/menus/options/narrator_options.nut")
let vehicleGroupLimitOptions = require("%ui/hud/menus/options/vehicle_group_limit_options.nut")
let qualityPresetOption = require("%ui/hud/menus/options/get_quality_preset_option.nut")

let options = [qualityPresetOption, cameraFovOption, vehicleCameraFovOption,
  vehicleCameraFollowOption, harmonizationOption]
options.extend(
  renderOptions, soundOptions, voiceChatOptions, cameraShakeOptions, violenceOptions,
  planeContolOptions, hudOptions, narratorOptions, vehicleGroupLimitOptions
)

setMenuOptions(options)

menuTabsOrder([
  {id = "Graphics", text=loc("options/graphicsParameters")},
  {id = "Sound", text = loc("sound")},
  {id = "Game", text = loc("options/game")},
  {id = "VoiceChat", text = loc("controls/tab/VoiceChat")},
])

let hitMarksState = require("%ui/hud/state/hit_marks_es.nut")
hitMarksState.worldKillMarkColor(Color(220,220,220,150))
hitMarksState.hitSize([fsh(2), fsh(2)])
hitMarksState.killSize([fsh(2), fsh(2)])
hitMarksState.worldDownedMarkColor(0)
hitMarksState.worldKillTtl(2.5)

