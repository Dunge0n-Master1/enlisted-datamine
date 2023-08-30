from "%enlSqGlob/ui_library.nut" import *

let { darkPanelBgColor, accentColor } = require("%enlSqGlob/ui/designConst.nut")
let { mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")


let function emptyProgress(val, color, anim = null) {
  return {
    key = val
    rendObj = ROBJ_SOLID
    size = flex()
    color = color ?? darkPanelBgColor
    transform = {
      pivot = [1, 0]
      scale = [val / 100.0, 1]
    }
    animations = anim
  }
}

let receivedProgress = @(val, color){
  rendObj = ROBJ_SOLID
  size = [pw(val), flex()]
  color = color ?? accentColor
}


let animOverride = { prop = AnimProp.scale, play = true }

let function makeProgressAnim(curProgress, wasProgress, hasNewLevel, onFinish) {
  if (wasProgress == null || (!hasNewLevel && wasProgress >= curProgress))
    return null

  let curFactor = (100 - curProgress) / 100.0
  let wasFactor = (100 - wasProgress) / 100.0
  if (!hasNewLevel) {
    let duration = max(wasFactor - curFactor, 0.2)
    return [
      { from = [wasFactor, 1], to = [curFactor, 1], duration, onFinish }.__update(animOverride)
    ]
  }

  let d1 = max(wasFactor, 0.2)
  let d2 = max(1.0 - curFactor, 0.2)
  return [
    { from = [wasFactor, 1], to = [0, 1], duration = d1 }.__update(animOverride)
    {
      from = [1, 1], to = [curFactor, 1], delay = d1, duration = d2, onFinish
    }.__update(animOverride)
  ]
}


let function progressBar(value, override = {}, progressToAnim = {}) {
  let curProgress = clamp(100.0 * value, 0, 100)
  let { wasProgress = null, hasNewLevel = false } = progressToAnim
  let anim = makeProgressAnim(curProgress, wasProgress, hasNewLevel, @() progressToAnim.clear())
  let bgColor = override?.bgColor
  let progressColor = override?.progressColor
  return {
    size = [flex(), hdpxi(10)]
    children = [
      receivedProgress(curProgress, progressColor)
      emptyProgress(100 - curProgress, bgColor, anim)
    ]
  }.__update(override)
}


let receivedGradProgress = @(image) {
  rendObj = ROBJ_IMAGE
  size = flex()
  image
}


let function gradientProgressBar(value, override = {}, progressToAnim = {}) {
  let curProgress = clamp(100.0 * value, 0, 100)
  let { wasProgress = null, hasNewLevel = false } = progressToAnim
  let anim = makeProgressAnim(curProgress, wasProgress, hasNewLevel, @() progressToAnim.clear())
  let bgImage = override.bgImage
  let emptyColor = override?.emptyColor ?? darkPanelBgColor
  return {
    size = [flex(), hdpxi(10)]
    children = [
      receivedGradProgress(bgImage)
      emptyProgress(100 - curProgress, emptyColor, anim)
    ]
  }.__update(override)
}


let gradient = mkTwoSidesGradientX({sideColor = 0x00FFFFFF, centerColor=0x1AFFFFFF, isAlphaPremultiplied=false})

let doubleSideHighlightLine = freeze({
  rendObj = ROBJ_IMAGE
  size = [flex(), hdpx(4)]
  image = gradient
})

let doubleSideHighlightLineBottom = freeze({
  rendObj = ROBJ_IMAGE
  size = [flex(), hdpx(4)]
  image = gradient
  vplace = ALIGN_BOTTOM
})
let mainTitleImg = mkTwoSidesGradientX({sideColor=0x002B2D44, centerColor=0xE642516C, isAlphaPremultiplied=false})
let doubleSideBg = @(content) {
  rendObj = ROBJ_IMAGE
  size = flex()
  image = mainTitleImg
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = content
}


return {
  progressBar
  gradientProgressBar
  doubleSideHighlightLine
  doubleSideBg
  doubleSideHighlightLineBottom
}