from "%enlSqGlob/ui_library.nut" import *

let {showPushObjectTip} = require("%ui/hud/state/push_object_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let function push_object_tip() {
  let res = { watch = showPushObjectTip }
  if (!showPushObjectTip.value)
    return res
  return res.__update({
    size = SIZE_TO_CONTENT
    children = tipCmp({
      text = loc("hint/pushObject")
      inputId = "Human.PushObject"
    })
  })
}

return push_object_tip
