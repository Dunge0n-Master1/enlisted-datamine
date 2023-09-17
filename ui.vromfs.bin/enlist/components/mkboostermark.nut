from "%enlSqGlob/ui_library.nut" import *

let fa = require("%ui/components/fontawesome.map.nut")
let { fontSub, fontawesome } = require("%enlSqGlob/ui/fontsStyle.nut")
let { round } = require("math")

let darkColor = 0xFF113322

let boosterBack = {
  rendObj = ROBJ_9RECT
  size = [flex(), hdpxi(60)]
  texOffs = [5, 25, 10, 5]
  screenOffs = [5, 25, 10, 5]
  image = Picture($"!ui/skin#booster_bg.svg?Ac")
}

let downArrow = {
  rendObj = ROBJ_TEXT
  color = 0xFFCC3300
  text = fa["arrow-circle-down"]
}.__update(fontawesome, {fontSize = hdpxi(15)})

let function mkBoosterText(expMul, expPenalty) {
  let boosterVal = round(((expMul + 1.0) * (expPenalty + 1.0) - 1.0) * 100)
  let text = loc("expBooster", { booster = boosterVal >= 0 ? $"+{boosterVal}" : boosterVal })
  return {
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
      }.__update(fontSub)
    ]
  }
}

let mkInfoText = @(text) "" == (text ?? "") ? null
  : {
      rendObj = ROBJ_TEXT
      color = darkColor
      text
    }.__update(fontSub)

let mkBoosterMark = @(expMul, expPenalty = 0.0, infoText = null, override = {}) {
  size = [SIZE_TO_CONTENT, hdpxi(60)]
  children = [
    boosterBack
    {
      flow = FLOW_VERTICAL
      padding = [hdpxi(5), hdpxi(15), hdpxi(10), hdpxi(10)]
      children = [
        mkBoosterText(expMul, expPenalty)
        mkInfoText(infoText)
      ]
    }
  ]
}.__update(override)

return mkBoosterMark
