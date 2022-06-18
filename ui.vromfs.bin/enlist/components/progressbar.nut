from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let mkProgress = @(maxValue, curValue, addValue, progressColor, addColor, addValueAnimations = null) {
  size = flex()
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_LEFT
  children = [
    {
      rendObj = ROBJ_SOLID
      color = progressColor
      size = [pw(maxValue > 0 ? min(100.00 * (curValue.tofloat() / maxValue.tofloat()), 100) : 0), flex()]
    }
    {
      rendObj = ROBJ_SOLID
      color = addColor
      size = [pw(maxValue > 0 ? min(100.00 * (addValue.tofloat() / maxValue.tofloat()), 100) : 0), flex()]
      transform = { pivot =[0, 0] }
      animations = addValueAnimations
    }
  ]
}

let blinkAnimation = [
  { prop = AnimProp.opacity, from = 0.7, to = 1, duration = 1,
    play = true, loop = true, easing = Blink }
]

let mkProgressText = @(maxValue, curValue, completeText, hasBlink) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = curValue >= maxValue && (completeText ?? "").len() > 0
    ? completeText
    : $"{curValue}/{maxValue}"
  animations = hasBlink ? blinkAnimation : null
}.__update(sub_txt)

local function mkProgressBar(maxValue, curValue, height,
    addValue = 0,
    addValueAnimations = null,
    needText = false,
    completeText = "",
    hasBlink = false,
    addGauge = null,
    backColor = Color(19, 19, 19),
    progressColor = Color(174, 140, 99),
    addColor = Color(255, 198, 44)) {
  curValue = min(curValue, maxValue)
  addValue = min(maxValue - curValue, addValue)
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), height]
    color = backColor
    children = [
      mkProgress(maxValue, curValue, addValue, progressColor, addColor, addValueAnimations)
      addGauge
      needText ? mkProgressText(maxValue, curValue + addValue, completeText, hasBlink) : null
    ]
  }
}

return kwarg(mkProgressBar)