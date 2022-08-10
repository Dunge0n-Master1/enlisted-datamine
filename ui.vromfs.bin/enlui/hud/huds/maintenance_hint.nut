from "%enlSqGlob/ui_library.nut" import *

let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let {hasRepairKit, hasExtinguisher, canMaintainVehicle, isRepairRequired, isExtinguishRequired} = require("%ui/hud/state/vehicle_maintenance_state.nut")

let keyId = "Human.VehicleMaintenance"

let function action() {
  let res = {
    size = SIZE_TO_CONTENT
    watch = [hasRepairKit, hasExtinguisher, canMaintainVehicle, isRepairRequired, isExtinguishRequired]
  }
  let extinguishAvailable = canMaintainVehicle.value && hasExtinguisher.value && isExtinguishRequired.value
  let repairAvailable = canMaintainVehicle.value && hasRepairKit.value && isRepairRequired.value
  if (!extinguishAvailable && !repairAvailable)
    return res

  res.children <- [tipCmp({
    text = extinguishAvailable
      ? loc("hud/extinguish", "Hold to extinguish")
      : loc("hud/repair", "Hold to repair")
    inputId = keyId
    textColor = DEFAULT_TEXT_COLOR
  })]

  return res
}

return action