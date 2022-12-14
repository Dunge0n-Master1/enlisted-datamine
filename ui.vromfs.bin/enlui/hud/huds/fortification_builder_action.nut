from "%enlSqGlob/ui_library.nut" import *

let {actionTimer} = require("%ui/hud/state/fortification_builder_action.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")

let endTimerTime = Computed(@() actionTimer.value.endTimeToComplete ?? 0.0)
let countDownTimer = mkCountdownTimer(endTimerTime)
let curProgressW = Computed(@() actionTimer.value.totalTime > 0 ?
 (1 - (countDownTimer.value / actionTimer.value.totalTime)) * actionTimer.value.actionTimerMul + actionTimer.value.curProgress : 0)
let showProgress = Computed(@() curProgressW.value > 0.0 && curProgressW.value < 0.99)
let actionTimerColor = Computed(@() actionTimer.value.actionTimerColor)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]

let progressIconSize = hdpx(50)

let destroyingProgress = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      color = Color(255, 255, 255)
      size = [progressIconSize, progressIconSize]
      image = Picture($"!ui/uiskin/building_hammer.svg:{progressIconSize}:{progressIconSize}:K")
    }
    @() {
      watch = actionTimerColor
      behavior = Behaviors.RtPropUpdate
      size = [hdpx(80), hdpx(80)]
      lineWidth = hdpx(6.0)
      color = actionTimerColor.value
      fillColor = Color(122, 1, 0, 0)
      commands
      rendObj = ROBJ_VECTOR_CANVAS
      function update() {
        sector[6] = 360.0 * curProgressW.value
      }
    }
  ]
}

return @() {
  watch = showProgress
  children = showProgress.value ? destroyingProgress : null
}
