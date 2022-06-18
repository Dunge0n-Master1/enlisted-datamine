from "%enlSqGlob/ui_library.nut" import *

let {getTips, tipsGen} = require("%ui/hud/state/tips.nut")

let tipsBlock = {
  gap = fsh(1)
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

return @() {
  watch = tipsGen
  size = flex()
  children = (getTips() ?? []).map(@(tipGroup) tipsBlock.__merge(tipGroup))
}
