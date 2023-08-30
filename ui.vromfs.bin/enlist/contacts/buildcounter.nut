from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let {TextHighlight, BtnTextHover} = require("%ui/style/colors.nut")

let buildCounter = @(counterWatch, overrride = {}) @() {
  watch = counterWatch
  vplace = ALIGN_TOP
  pos = [0, -hdpx(10)]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  color = TextHighlight
  fontFx = FFT_GLOW
  fontFxColor = BtnTextHover
  text = counterWatch.value
}.__update(fontSub, overrride)

return buildCounter