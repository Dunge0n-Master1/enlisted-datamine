from "%enlSqGlob/ui_library.nut" import *

let {isRepairFortification, repairFortificationTimeTotal, repairFortificationEndTime} = require("%ui/hud/state/fortification_repair_state.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")
let faComp = require("%ui/components/faComp.nut")

let resupplyTimer = mkCountdownTimer(repairFortificationEndTime)
let resupplyProgress = Computed(@() repairFortificationTimeTotal.value > 0 ? (1 - (resupplyTimer.value / repairFortificationTimeTotal.value)) : 0)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]
let resupplyIndicatorSize = [hdpx(80), hdpx(80)]
let resupplyIndicator = @() {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    faComp("rotate-left", {
      color = Color(255, 255, 255)
      fontSize = hdpx(40)
    })
    {
      behavior = Behaviors.RtPropUpdate
      size = resupplyIndicatorSize
      lineWidth = hdpx(6.0)
      color = Color(0, 255, 0)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      commands = commands
      update = function() {
        sector[6] = 360.0 * resupplyProgress.value
      }
    }
  ]
}

return @() {
  watch = [isRepairFortification]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM

  children = isRepairFortification.value ? resupplyIndicator() : null
}