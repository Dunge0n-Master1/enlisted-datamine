from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")

let function indicatorCtor(endTime, totalTime, text=null){
  let countDownTimer = mkCountdownTimer(endTime)
  let curProgressW = Computed(@() totalTime.value > 0 ? countDownTimer.value / totalTime.value : 0)
  let showProgress = Computed(@() curProgressW.value > 0.0 && curProgressW.value < 0.99)

  let changeSeatProgressSize = [hdpx(80), hdpx(80)]

  let commands = [
    [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
    [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
  ]
  let sector = commands[1]
  curProgressW.subscribe(@(v) sector[6] = 360.0 * v)

  let changeSeatProgress = {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    padding = text ? fsh(2) : null
    children = [
      faComp("exchange", {
        color = Color(255, 255, 255)
        fontSize = hdpx(30)
      })
      @() {
        watch = curProgressW
        size = changeSeatProgressSize
        lineWidth = hdpx(6.0)
        color = Color(255, 255, 255)
        fillColor = Color(122, 1, 0, 0)
        rendObj = ROBJ_VECTOR_CANVAS
        commands
      }
      text ? {
        rendObj = ROBJ_TEXT
        text
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_CENTER
        textColor = DEFAULT_TEXT_COLOR
        pos = [0, fsh(3)]
      }.__update(fontBody) : null
    ]
  }

  return function() {
    return {
      watch = [showProgress]
      children = showProgress.value ? changeSeatProgress : null
    }
  }
}

return indicatorCtor