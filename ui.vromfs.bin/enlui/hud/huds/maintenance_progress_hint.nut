from "%enlSqGlob/ui_library.nut" import *

let {isExtinguishing, isRepairing, maintenanceTime, maintenanceTotalTime} = require("%ui/hud/state/vehicle_maintenance_state.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")
let faComp = require("%ui/components/faComp.nut")

let maintenanceTimer = mkCountdownTimer(maintenanceTime)
let maintenanceProgress = Computed(@() maintenanceTotalTime.value > 0 ? (1 - (maintenanceTimer.value / maintenanceTotalTime.value)) : 0)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]
let maintenanceIndicatorSize = [hdpx(80), hdpx(80)]
let maintenanceIndicator = @(icon) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    faComp(icon, {
      color = Color(255, 255, 255)
      fontSize = hdpx(40)
    })
    {
      behavior = Behaviors.RtPropUpdate
      size = maintenanceIndicatorSize
      lineWidth = hdpx(6.0)
      color = Color(0, 255, 0)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      commands = commands
      update = function() {
        sector[6] = 360.0 * maintenanceProgress.value
      }
    }
  ]
}

return function () {
  let action = isExtinguishing.value ? "fire-extinguisher" : "wrench"

  return {
    watch = [maintenanceTime, maintenanceTimer]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = (maintenanceTime.value > 0 && (isRepairing.value || isExtinguishing.value)) ? maintenanceIndicator(action) : null
  }
}