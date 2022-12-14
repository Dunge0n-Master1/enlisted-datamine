from "%enlSqGlob/ui_library.nut" import *

let { panelBgColor, accentColor, colPart } = require("%enlSqGlob/ui/designConst.nut")


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


return {
  progressBar
  gradientProgressBar
}