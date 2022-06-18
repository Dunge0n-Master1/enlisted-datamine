from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
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
}.__update(sub_txt, overrride)

return buildCounter