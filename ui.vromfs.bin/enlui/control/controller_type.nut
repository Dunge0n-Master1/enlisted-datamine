from "%enlSqGlob/ui_library.nut" import *

let { platformId } = require("%dngscripts/platform.nut")
let sharedWatched = require("%dngscripts/sharedWatched.nut")
let controlsTypes = require("controls_types.nut")
let eventbus = require("eventbus")
let {GAMEPAD_VENDOR_SONY, GAMEPAD_VENDOR_NINTENDO} = require("dainput2")
let gamepadTypeByPlatform = {
  nswitch = controlsTypes.nxJoycon
  ps4 = controlsTypes.ds4gamepad
  ps5 = controlsTypes.ds4gamepad
}
let defGamepadType = gamepadTypeByPlatform?[platformId] ?? controlsTypes.x1gamepad

let gamepadType = sharedWatched("gamepadType", @() defGamepadType)

console_register_command(@(value) eventbus.send("input_gamepad_type", {ctype=value}), "ui.changegamepad")

eventbus.subscribe("input_gamepad_type", function(msg) {
  let val = msg.ctype
  gamepadType( val==GAMEPAD_VENDOR_SONY ? controlsTypes.ds4gamepad
             : val==GAMEPAD_VENDOR_NINTENDO ? controlsTypes.nxJoycon
             : controlsTypes.x1gamepad)
})

wlog(gamepadType, "ui.changegamepad-->")

return gamepadType