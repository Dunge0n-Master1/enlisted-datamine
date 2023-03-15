from "%enlSqGlob/ui_library.nut" import gui_scene, log

let {DBGLEVEL} = require("dagor.system")
let { platformId, is_sony, is_ps5, is_xbox, is_xbox_scarlett, is_pc } = require("%dngscripts/platform.nut")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let dainput = require("dainput2")
let { logerr } = require("dagor.debug")
let { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")
let {ControlsTypes, setForcedControlsType } = require("%ui/control/active_controls.nut")

/*ATTENTION!
  here are onlineSharedOption! They are not supposed to work until login!
  this meant that they are not also correct on login page
  and also with disableMenu
  Fix it somehow later
    probably - save it in separate block on change in game_settings and they should be rewrited by online settings
*/

let clickRumbleSettingId = "input/clickRumbleEnabled"
let uiClickRumbleSave = mkOnlineSaveData(clickRumbleSettingId,
  @() get_setting_by_blk_path(clickRumbleSettingId) ?? gui_scene.config.clickRumbleEnabled)

let isUiClickRumbleEnabled = uiClickRumbleSave.watch
gui_scene.setConfigProps({clickRumbleEnabled = isUiClickRumbleEnabled.value})
let setUiClickRumble = uiClickRumbleSave.setValue
isUiClickRumbleEnabled.subscribe(function(val) {
  gui_scene.setConfigProps({clickRumbleEnabled = val})
  set_setting_by_blk_path(clickRumbleSettingId, val)
  save_settings()
})

let inBattleRumbleSettingId = "input/inBattleRumbleEnabled"
let inBattleRumbleSave = mkOnlineSaveData(inBattleRumbleSettingId, @() get_setting_by_blk_path(inBattleRumbleSettingId) ?? true)

let isInBattleRumbleEnabled = inBattleRumbleSave.watch
let setInBattleRumble = inBattleRumbleSave.setValue
isInBattleRumbleEnabled.subscribe(function(val) {
  set_setting_by_blk_path(inBattleRumbleSettingId, val)
  save_settings()
})

let isAimAssistExists = is_xbox || is_sony
let aimAssistSave = mkOnlineSaveData("game/aimAssist", @() isAimAssistExists, @(v) v && isAimAssistExists)
let isAimAssistEnabled = aimAssistSave.watch
let setAimAssist = isAimAssistExists ? aimAssistSave.setValue
  : @(_) logerr("Try to change aim assist while it not enabled")

let defaultDz = is_ps5 || is_xbox_scarlett
  ? 0.1
  : 0.15
let validateDz = @(v) clamp(v, 0.0, 0.4)
const gamepadCursorDeadZoneMin = 0.15

let function setGamepadCursorDz(stick_dz){
  local target_dz = gamepadCursorDeadZoneMin
  if (stick_dz > 0)
    target_dz =  stick_dz<1 ? clamp((gamepadCursorDeadZoneMin - stick_dz) / (1 - stick_dz), 0.01, 0.3) : 0.3
  gui_scene.setConfigProps({gamepadCursorDeadZone = target_dz})
  log("set gamepadCursorDeadZone to: ", target_dz,".Current dz in driver for stick:", stick_dz)
}

let stick0Save = mkOnlineSaveData($"controls/{platformId}/stick0_dz_ver2", @() defaultDz, validateDz)
let stick0_dz = stick0Save.watch

let function stick0_dz_apply(...) {
  let stick_dz = stick0_dz.value
  dainput.set_main_gamepad_stick_dead_zone(0, stick_dz)
  if (gui_scene.config.gamepadCursorAxisH == 0 || gui_scene.config.gamepadCursorAxisV == 1)
    setGamepadCursorDz(stick_dz)
}

stick0_dz.subscribe(stick0_dz_apply)
stick0_dz_apply()

let stick1Save = mkOnlineSaveData($"controls/{platformId}/stick1_dz_ver2", @() defaultDz, validateDz)
let stick1_dz = stick1Save.watch

let function stick1_dz_apply(...) {
  let stick_dz = stick1_dz.value
  dainput.set_main_gamepad_stick_dead_zone(1, stick_dz)
  if (gui_scene.config.gamepadCursorAxisH == 2 || gui_scene.config.gamepadCursorAxisV == 3)
    setGamepadCursorDz(stick_dz)
}

stick1_dz.subscribe(stick1_dz_apply)
stick1_dz_apply()

let defaultAimSmooth = is_sony || is_xbox
  ? 0.00
  : 0.25
let validateAimSmooth = @(v) clamp(v, 0.0, 0.5)
let aimSmoothSave = mkOnlineSaveData("game/aimSmooth", @() defaultAimSmooth, validateAimSmooth)

let useGamepad = mkOnlineSaveData("game/useGamepad",
  function() {
    if (is_pc)
      return DBGLEVEL ? ControlsTypes.AUTO : ControlsTypes.KB_MOUSE
    return ControlsTypes.GAMEPAD
  },
  @(v) [ControlsTypes.AUTO, ControlsTypes.KB_MOUSE, ControlsTypes.GAMEPAD].contains(v)
    ? v
    : is_pc
      ? ControlsTypes.KB_MOUSE
      : ControlsTypes.GAMEPAD
)
let use_gamepad_state = useGamepad.watch
let function set_use_gamepad(v) {
  setForcedControlsType(v)
  useGamepad.setValue(v)
}
setForcedControlsType(use_gamepad_state.value)

let onlineControls = {
  setUiClickRumble
  isUiClickRumbleEnabled

  setInBattleRumble
  isInBattleRumbleEnabled

  isAimAssistExists
  isAimAssistEnabled
  setAimAssist
  stick0_dz
  set_stick0_dz = stick0Save.setValue
  stick1_dz
  set_stick1_dz = stick1Save.setValue
  aim_smooth = aimSmoothSave.watch
  aim_smooth_set = aimSmoothSave.setValue
  set_use_gamepad
  use_gamepad_state
}

return onlineControls

