from "%enlSqGlob/ui_library.nut" import *

let {showGrenadeRethrowTip} = require("%ui/hud/state/grenade_rethrow_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")


return function() {
  let res = { watch = showGrenadeRethrowTip }
  if (!showGrenadeRethrowTip.value)
    return res

  return res.__update({
    size = SIZE_TO_CONTENT
    children = tipCmp({
      text = loc("hud/throw_back")
      inputId = "Human.ThrowBack"
    })
  })
}
