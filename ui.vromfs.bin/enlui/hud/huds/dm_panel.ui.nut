from "%enlSqGlob/ui_library.nut" import *

let {isVisible} = require("%ui/hud/state/dm_panel.nut")

return @() {
  watch = [isVisible]
  size = !isVisible.value ? null : [hdpx(220), hdpx(220)]
  children = !isVisible.value ? null : {
    rendObj = ROBJ_WORLD_BLUR
    fillColor = Color(0,0,0,80)
    size = flex()
    children = {
      size = flex()
      rendObj = ROBJ_XRAYDOLL
      behavior = Behaviors.DMPanel
    }
  }
}