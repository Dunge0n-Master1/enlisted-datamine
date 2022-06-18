from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {inVehicle, isGunner, isDriver, isVehicleAlive} = require("%ui/hud/state/vehicle_state.nut")

return function () {
  local tip = null
  if (inVehicle.value && isVehicleAlive.value) {
    local text = null
    if (isDriver.value) {
      text = loc("hud/vehicle_control_hint/driver", "You're controlling vehcile's movement")
    } else if (isGunner.value) {
      text = loc("hud/vehicle_control_hint/gunner", "You're controlling vehcile's main turret")
    }

    if (text != null) {
      tip = tipCmp({text}.__update(sub_txt))
    }
  }

  return {
    watch = [
      inVehicle
      isVehicleAlive
      isGunner
      isDriver
    ]

    children = tip
  }
}
