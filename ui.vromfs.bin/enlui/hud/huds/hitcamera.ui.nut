from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let {isVisible, totalMembersBeforeShot, deadMembers} = require("%ui/hud/state/hitcamera.nut")

return @() {
  watch = [isVisible]
  size = !isVisible.value ? null : [hdpx(432), hdpx(198)]
  children = !isVisible.value ? null : {
    rendObj = ROBJ_WORLD_BLUR
    fillColor = Color(0,0,0,80)
    size = flex()
    flow = FLOW_VERTICAL
    children = [
      {
        rendObj=ROBJ_TEXT
        color = Color(190,190,190,180)
        text = (totalMembersBeforeShot.value == 0)
                ? loc("hitcameraKillledMembers/empty")
                : (deadMembers.value != 0)
                ? loc("hitcameraKillledMembers/killed", {deadMembers=deadMembers.value})
                : loc("hitcameraKillledMembers/notKilled")
      }.__update(fontBody)
      {
        size = flex()
        behavior = Behaviors.HitCamera
      }
    ]
  }
}