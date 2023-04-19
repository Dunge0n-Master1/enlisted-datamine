from "%enlSqGlob/ui_library.nut" import *

let fa = require("%ui/components/fontawesome.map.nut")
let { sub_txt, tiny_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let { round } = require("math")

let darkColor = 0xFF113322

let downArrow = {
  rendObj = ROBJ_TEXT
  color = 0xFFCC3300
  text = fa["arrow-circle-down"]
}.__update(fontawesome, {fontSize = fsh(1.35)})

let function mkBoosterMark(expMul, expPenalty = 0.0, infoText = null, override = {}) {
  let offs = [5, 25, 10, 5]
  let boosterVal = round(((expMul + 1.0) * (expPenalty + 1.0) - 1.0) * 100)
  let text = loc("expBooster", { booster = boosterVal >= 0 ? $"+{boosterVal}" : boosterVal })

  return {
    rendObj = ROBJ_9RECT
    image = Picture($"!ui/skin#booster_bg.svg?Ac")
    texOffs = offs
    screenOffs = offs
    padding = [hdpxi(5), hdpxi(15), hdpxi(10), hdpxi(10)]
    size = [SIZE_TO_CONTENT, hdpxi(60)]

    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER

    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(5)
        children = [
          expPenalty != 0 ? downArrow : null
          {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            color = darkColor
            text
          }.__update(sub_txt)
        ]
      }
      "" == (infoText ?? "") ? null
        : {
            rendObj = ROBJ_TEXT
            color = darkColor
            text = infoText
          }.__update(tiny_txt)
    ]
  }.__update(override)
}

return mkBoosterMark
