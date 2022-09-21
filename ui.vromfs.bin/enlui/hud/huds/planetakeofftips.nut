from "%enlSqGlob/ui_library.nut" import *

let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")

let { isVehicleAlive, isPlaneOnCarrier } = require("%ui/hud/state/vehicle_state.nut")

let function throttle() {
  let res = { watch = [isPlaneOnCarrier, isVehicleAlive] }
  if (!isPlaneOnCarrier.value || !isVehicleAlive.value)
    return res
  return res.__update({
    children = tipCmp({
      text = loc("hud/planeTakeOffIncreaseThrottle")
      inputId = "Plane.Throttle"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

let function rudder() {
  let res = { watch = [isPlaneOnCarrier, isVehicleAlive] }
  if (!isPlaneOnCarrier.value || !isVehicleAlive.value)
    return res
  return res.__update({
    children = tipCmp({
      text = loc("hud/planeTakeOffUseRudder")
      inputId = "Plane.Rudder"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

return [
  rudder
  throttle
]