from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let defcomps = require("%enlSqGlob/ui/defcomps.nut")
let {
  blinkingSignalsGreenDark, blinkingSignalsGreenNormal
} = require("%enlSqGlob/ui/viewConst.nut")

let function blinkingIcon(iconId, text = null, isSelected = false) {
  let color = isSelected ? blinkingSignalsGreenDark : blinkingSignalsGreenNormal
  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [hdpx(2), hdpx(3), 0, 0]
    gap = hdpx(1)
    transform = {}
    animations = [ { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1, play = true, loop = true, easing = Blink } ]
    children = [
      faComp(iconId, { fontSize = hdpx(11), color})
      text != null ? defcomps.note({ text, color }) : null
    ]
  }
}

return blinkingIcon