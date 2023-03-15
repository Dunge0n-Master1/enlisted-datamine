from "%enlSqGlob/ui_library.nut" import *

let { platformId } = require("%dngscripts/platform.nut")
let controlsTypes = require("controls_types.nut")
let eventbus = require("eventbus")
let { GAMEPAD_VENDOR_SONY } = require("dainput2")
let gamepadTypeByPlatform = {
  ps4 = controlsTypes.ds4gamepad
  ps5 = controlsTypes.ds4gamepad
}
let defGamepadType = gamepadTypeByPlatform?[platformId] ?? controlsTypes.x1gamepad

let gamepadType = mkWatched(persist, "gamepadType", defGamepadType)

let function setInput(msg){
  let {ctype} = msg
  gamepadType(ctype == GAMEPAD_VENDOR_SONY
                ? controlsTypes.ds4gamepad
                : controlsTypes.x1gamepad)
}
eventbus.subscribe("input_gamepad_type", setInput)
console_register_command(@(value) setInput({ctype=value}), "ui.changegamepad")

wlog(gamepadType, "ui.changegamepad-->")

return gamepadType