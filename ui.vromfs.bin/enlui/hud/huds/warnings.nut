from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { warningsList } = require("%ui/hud/state/warnings.nut")
let { strokeStyle } = require("%enlSqGlob/ui/viewConst.nut")

let warnText = kwarg(@(locId, color = Color(255,120,120,255)) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color
  text = loc(locId)
  animations = [
    { prop=AnimProp.opacity, from=0.8, to=1.0, duration=0.6, play=true, loop=true, easing=CosineFull}
  ]
}.__update(fontHeading2, strokeStyle))

return function() {
  let curWarning = warningsList.value?[0]
  return {
    watch = warningsList
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    size = [flex(), SIZE_TO_CONTENT]
    children = curWarning ? warnText(curWarning, KWARG_NON_STRICT) : null
  }
}