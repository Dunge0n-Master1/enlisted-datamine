from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let {UnseenGlow, UnseenIcon} = require("%ui/style/colors.nut")

return function(amount = 1) {
  if (amount < 1)
    return {}
  let needCounter = amount < 10
  return faComp(needCounter ? "circle" : "exclamation-circle", {
    size = [hdpx(32), hdpx(32)]
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = UnseenIcon
    fontSize = hdpx(16)
    fontFxColor = UnseenGlow
    fontFxFactor = min(64,hdpx(64))
    fontFx = FFT_GLOW

    animations = [ { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1, play = true, loop = true, easing = Blink} ]

    children = needCounter
      ? {
          rendObj = ROBJ_TEXT
          color = 0xFF000000
          text = amount
          pos = [0, hdpx(-1)] //more correct center text visualy
        }.__update(sub_txt)
      : null
  })
}