from "%enlSqGlob/ui_library.nut" import *

let { panelBgColor, accentColor, colPart } = require("%enlSqGlob/ui/designConst.nut")
let { mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")


let emptyProgress = @(val, color) {
  rendObj = ROBJ_SOLID
  size = [pw(val), flex()]
  color = color ?? panelBgColor
}

let receivedProgress = @(val, color){
  rendObj = ROBJ_SOLID
  size = [pw(val), flex()]
  color = color ?? accentColor
}

let function progressBar(value, override = {}) {
  let valueProgress = clamp(100.0 * value, 0, 100)
  let bgColor = override?.bgColor
  let progressColor = override?.progressColor
  return {
    size = [flex(), hdpx(10)]
    flow = FLOW_HORIZONTAL
    children = [
      receivedProgress(valueProgress, progressColor)
      emptyProgress(100 - valueProgress, bgColor)
    ]
  }.__update(override)
}


let receivedGradProgress = @(image){
  rendObj = ROBJ_IMAGE
  size = flex()
  image
}

let function gradientProgressBar(value, override = {}) {
  let valueProgress = clamp(100.0 * value, 0, 100)
  let bgImage = override.bgImage
  let emptyColor = override?.emptyColor ?? panelBgColor
  return {
    size = [flex(), colPart(0.161)]
    flow = FLOW_HORIZONTAL
    children = [
      receivedGradProgress(bgImage)
      emptyProgress(100 - valueProgress, emptyColor)
    ]
  }.__update(override)
}


let gradient = mkTwoSidesGradientX(0x00FFFFFF, 0x1AFFFFFF, false)
let doubleSideHighlightLine = @(override = {}) {
  rendObj = ROBJ_IMAGE
  size = [flex(), colPart(0.06)]
  image = gradient
}.__update(override)


let mainTitleImg = mkTwoSidesGradientX(0x002B2D44, 0xE642516C, false)
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
}