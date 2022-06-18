from "%enlSqGlob/ui_library.nut" import *

let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let style = require("%ui/hud/style.nut")
let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {vehicleRepairTime} = require("%ui/hud/state/vehicle_maintenance_state.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")

let {secondsToTimeSimpleString} = require("%ui/helpers/time.nut")

let repairTimer = mkCountdownTimer(vehicleRepairTime)
return function () {
  local tip = null
  if (inVehicle.value && vehicleRepairTime.value > 0) {
    tip = tipCmp({
      text = loc("hud/vehicle_repair", "Vehicle repair in progress, {time} left",
        {time = secondsToTimeSimpleString(repairTimer.value)})
      textColor =  style.DEFAULT_TEXT_COLOR
    })
  }

  return {
    watch = [ inVehicle, vehicleRepairTime, repairTimer ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = tip
  }
}