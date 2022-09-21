from "ui_library.nut" import *

let { globalWatched } = require("%dngscripts/globalState.nut")
let {controllerDisconnected, controllerDisconnectedUpdate} = globalWatched("controllerDisconnected", @() false)
console_register_command(@() controllerDisconnectedUpdate(!controllerDisconnected.value), "ui.controllerDisconnected")

return {
  controllerDisconnected,
  controllerDisconnectedUpdate
}