from "%enlSqGlob/ui_library.nut" import gui_scene, mkWatched, Computed, Watched, log

let console_register_command = require("console").register_command
let {set_actions_binding_column_active} = require("dainput2")
let eventbus = require("eventbus")
let platform = require("%dngscripts/platform.nut")
let controlsTypes = require("controls_types.nut")
let forcedControlsType = mkWatched(persist, "forcedControlsType")
let defRaw = platform.is_pc ? 0 : 1
let lastActiveControlsTypeRaw = mkWatched(persist, "lastActiveControlsTypeRaw", defRaw)
let def = platform.isTouchPrimary
          ? controlsTypes.touch
          : platform.is_pc
            ? controlsTypes.keyboardAndMouse
            : platform.is_sony
              ? controlsTypes.ds4gamepad
              : controlsTypes.x1gamepad

let lastActiveControlsType = mkWatched(persist, "lastActiveControlType", def)

const EV_FORCE_CONTROLS_TYPE = "forced_controls_type"
let function setForcedControlsType(v){
  forcedControlsType(v)
}

enum ControlsTypes {
  AUTO = 0
  KB_MOUSE = 1
  GAMEPAD = 2
}

console_register_command(@(value) eventbus.send(EV_FORCE_CONTROLS_TYPE, {val=value}), "ui.debugControlsType")
eventbus.subscribe(EV_FORCE_CONTROLS_TYPE, @(msg) setForcedControlsType(msg.val))

const EV_INPUT_USED = "input_dev_used"

let function update_input_types(new_val){
  let map = {
    [1] = platform.isTouchPrimary ? controlsTypes.touch : controlsTypes.keyboardAndMouse,
    [2] = controlsTypes.x1gamepad,
    //[3] = controlsTypes.ds4gamepad, //< no such value sent
  }
  local ctype = map?[new_val] ?? def
  if (platform.is_sony && ctype==controlsTypes.x1gamepad)
    ctype = controlsTypes.ds4gamepad
  lastActiveControlsTypeRaw.update(new_val ?? defRaw)
  lastActiveControlsType.update(ctype)
}

forcedControlsType.subscribe(function(val) {
  if (val)
    update_input_types(val)
})

eventbus.subscribe(EV_INPUT_USED, function(msg) {
  if ([null, 0].contains(forcedControlsType.value))
    update_input_types(msg.val)
})

let isTouch = Computed(@() lastActiveControlsType.value == controlsTypes.touch)
keepref(isTouch)

let isGamepad = Computed(@() forcedControlsType.value == ControlsTypes.GAMEPAD || [
                                  controlsTypes.x1gamepad,
                                  controlsTypes.ds4gamepad
                                ].contains(lastActiveControlsType.value)
                            )
keepref(isGamepad)

const GAMEPAD_COLUMN = 1
let wasGamepad = mkWatched(persist, "wasGamepad", function() {
  let wasGamepadV = platform.is_pc ? false : true
  gui_scene.setConfigProps({gamepadCursorControl = wasGamepadV})
  return wasGamepadV
}())

let enabledGamepadControls = Watched(!platform.is_pc || isGamepad.value)

if (platform.is_pc){
  wasGamepad.subscribe(@(v) enabledGamepadControls(v))
  let setGamePadActive = @(v) set_actions_binding_column_active(GAMEPAD_COLUMN, v && forcedControlsType.value != ControlsTypes.KB_MOUSE)
  enabledGamepadControls.subscribe(setGamePadActive)
  forcedControlsType.subscribe(@(_) setGamePadActive(enabledGamepadControls.value))
  setGamePadActive(isGamepad.value)
}

isGamepad.subscribe(function(v) {
  wasGamepad(wasGamepad.value || v)
  log($"isGamepad changed to = {v}")
  gui_scene.setConfigProps({gamepadCursorControl = v})
})


return {
  controlsTypes
  lastActiveControlsType
  lastActiveControlsTypeRaw
  isGamepad
  isTouch
  wasGamepad
  enabledGamepadControls
  forcedControlsType
  ControlsTypes
  setForcedControlsType
}
