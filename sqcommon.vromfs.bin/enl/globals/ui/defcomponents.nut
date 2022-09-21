from "%enlSqGlob/ui_library.nut" import *

let { panelBgColor, accentColor } = require("%enlSqGlob/ui/designConst.nut")


let emptyProgress = @(val) {
  rendObj = ROBJ_SOLID
  size = [pw(val), flex()]
  color = panelBgColor
}

let receivedProgress = @(val){
  rendObj = ROBJ_SOLID
  size = [pw(val), flex()]
  color = accentColor
}

let function progressBar(value, override = {}) {
  let valueProgress = clamp(100.0 * value, 0, 100)
  return {
    size = [flex(), hdpx(10)]
    flow = FLOW_HORIZONTAL
    children = [
      receivedProgress(valueProgress)
      emptyProgress(100 - valueProgress)
    ]
  }.__update(override)
}

return {
  progressBar
}