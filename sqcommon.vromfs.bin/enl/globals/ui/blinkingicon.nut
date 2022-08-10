from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let defcomps = require("%enlSqGlob/ui/defcomps.nut")
let { blinkingSignalsGreenDark } = require("%enlSqGlob/ui/viewConst.nut")

let blinkingIcon = @(iconId, text = null) {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  margin = [hdpx(2), hdpx(3), 0, 0]
  gap = hdpx(1)
  transform = {}
  animations = [{
    prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1,
    play = true, loop = true, easing = Blink
  }]
  children = [
    faComp(iconId, { fontSize = hdpx(13), color = blinkingSignalsGreenDark })
    text != null ? defcomps.note({ text, color = blinkingSignalsGreenDark }) : null
  ]
}

return blinkingIcon