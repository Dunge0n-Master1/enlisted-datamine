from "%enlSqGlob/ui_library.nut" import *

require("%ui/_packages/common_shooter/game_console.nut")
require("%ui/hud/state/on_disconnect_server_es.nut")
require("%ui/hud/state/assists_es.nut")
require("%ui/hud/state/rumble_es.nut")
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

let hud_under = require("hud_under.nut")
let {crosshairOverheat, crosshairReload, crosshairHitmarks, crosshairForbidden, crosshairOverlayTransparency, crosshair}
  = require("%ui/hud/huds/crosshair.nut")
let crosshairImmunity = require("%ui/hud/huds/immunity_crosshair.nut")
let turretCrosshair = require("%ui/hud/huds/enlisted_turret_crosshair.nut")
let vehicleCrosshair = require("%ui/hud/huds/vehicle_crosshair.nut")
let forestall = require("%ui/hud/huds/forestall.ui.nut")
let killMarks = require("%ui/hud/huds/kill_marks.nut")
let {posHitMarks} = require("%ui/hud/huds/hit_marks.nut")
let zonePointers = require("huds/zone_pointers.nut")
let resupplyPointers = require("huds/resupply_pointers.nut")
let landingPointers = require("huds/aircraft_respawn_landing_pointers.nut")
let respawn = require("%ui/hud/menus/respawn.nut")

let {setGameHud}  = require("%ui/hud/state/gameHuds.nut")
let all_tips = require("%ui/hud/huds/tips/all_tips.nut")
let hudLayout = require("%ui/hud/hud_layout.nut")
let {isAlive} = require("%ui/hud/state/health_state.nut")
let {debriefingShow} = require("state/debriefingStateInBattle.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let replayHudLayout = require("%ui/hud/replay/replay_hud_layout.nut")
let { canShowGameHudInReplay } = require("%ui/hud/replay/replayState.nut")

let showHuds = Computed(function(){
  return !(!isAlive.value || debriefingShow.value)
})
showHuds.subscribe(@(v) showPlayerHuds(v))
showPlayerHuds(showHuds.value)

let network_error = require("%ui/hud/huds/tips/network_error.nut")
let perfStats = require("%ui/hud/huds/perf_stats.nut")
let menusUi = require("hud_menus.nut")

let { setMenuOptions, menuTabsOrder } = require("%ui/hud/menus/settings_menu.nut")
let { violenceOptions } = require("%ui/hud/menus/options/violence_options.nut")
let { harmonizationOption } = require("%ui/hud/menus/options/harmonization_options.nut")
let planeContolOptions = require("%ui/hud/menus/options/plane_control_options.nut")
let { cameraShakeOptions } = require("%ui/hud/menus/options/camera_shake_options.nut")
let { hudOptions } = require("%ui/hud/menus/options/hud_options.nut")
let { minimalistHud } = require("%ui/hud/state/hudOptionsState.nut")
let { optXboxGraphicsPreset, optPSGraphicsPreset, dbgConsolePreset }  = require("%ui/hud/menus/console_preset_options.nut")
let { renderOptions } = require("%ui/hud/menus/options/render_options.nut")
let { soundOptions } = require("%ui/hud/menus/options/sound_options.nut")
let { cameraFovOption } = require("%ui/hud/menus/options/camera_fov_option.nut")
let { vehicleCameraFovOption } = require("%ui/hud/menus/vehicle_camera_fov_option.nut")
let { vehicleCameraFollowOption } = require("%ui/hud/menus/vehicle_camera_follow_option.nut")
let { voiceChatOptions } = require("%ui/hud/menus/options/voicechat_options.nut")
let { optGraphicsQualityPreset }  = require("%ui/hud/menus/quality_preset_option.nut")
let { forcedMinimalHud } = require("state/hudGameModes.nut")
let { showSquadSpawn } = require("%ui/hud/state/respawnState.nut")
let narratorOptions = require("%ui/hud/menus/options/narrator_options.nut")
let vehicleGroupLimitOptions = require("%ui/hud/menus/options/vehicle_group_limit_options.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let tutorialZonePointers = require("%ui/hud/tutorial/huds/tutorial_zone_pointers.nut")
let platform = require("%dngscripts/platform.nut")

let options = []
if (platform.is_xbox_scarlett || dbgConsolePreset.value == "xbox_scarlett") {
  options.append(optXboxGraphicsPreset)
}
else if (platform.is_ps5 || dbgConsolePreset.value == "ps5") {
  options.append(optPSGraphicsPreset)
}

options.append(optGraphicsQualityPreset, cameraFovOption, vehicleCameraFovOption, vehicleCameraFollowOption, harmonizationOption)
  .extend(renderOptions, soundOptions, voiceChatOptions, cameraShakeOptions, violenceOptions,
    planeContolOptions, hudOptions, narratorOptions, vehicleGroupLimitOptions
  )

setMenuOptions(options)

menuTabsOrder([
  {id = "Graphics", text=loc("options/graphicsParameters")},
  {id = "Sound", text = loc("sound")},
  {id = "Game", text = loc("options/game")},
  {id = "VoiceChat", text = loc("controls/tab/VoiceChat")},
])
let minHud = Computed(@() forcedMinimalHud.value || minimalistHud.value)

let function hud(){
  if (isReplay.value && !canShowGameHudInReplay.value)
    return {
      watch = canShowGameHudInReplay
      size = flex()
      children = replayHudLayout
    }

  let showPlayerHudsV = showHuds.value
  let notMinimalHud = !minHud.value
  let children = [
    notMinimalHud || showSquadSpawn.value ? zonePointers : null,
    isTutorial.value ? tutorialZonePointers : null,
    notMinimalHud ? resupplyPointers : null,
    notMinimalHud ? landingPointers : null,
    hud_under,
    showPlayerHudsV ? all_tips : null,
    hudLayout,
    notMinimalHud && showPlayerHudsV ? forestall : null,
    notMinimalHud && showPlayerHudsV ? crosshairImmunity : null,
    notMinimalHud && showPlayerHudsV ? killMarks : null,
    notMinimalHud && showPlayerHudsV ? posHitMarks : null,
    showPlayerHudsV && notMinimalHud ? turretCrosshair : null,
    showPlayerHudsV ? vehicleCrosshair : null,
    !isReplay.value ? respawn : null,
    isReplay.value ? replayHudLayout : null,
  ]
  if (showPlayerHudsV){
    children.append(crosshairForbidden, crosshairOverheat, crosshairReload,
      notMinimalHud ? crosshairHitmarks : null, crosshairOverlayTransparency, notMinimalHud ? crosshair : null)
  }
  children.append(network_error, perfStats)
  return {
    watch = [showHuds, isTutorial, minHud, showSquadSpawn, isReplay, canShowGameHudInReplay]
    size = flex()
    children
  }
}
setGameHud([hud, menusUi])

let hitMarksState = require("%ui/hud/state/hit_marks_es.nut")
hitMarksState.worldKillMarkColor(Color(220,220,220,150))
hitMarksState.hitSize([fsh(2), fsh(2)])
hitMarksState.killSize([fsh(2), fsh(2)])
hitMarksState.worldDownedMarkColor(0)
hitMarksState.worldKillTtl(2.5)


