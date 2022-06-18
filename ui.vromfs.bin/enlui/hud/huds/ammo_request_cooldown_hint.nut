from "%enlSqGlob/ui_library.nut" import *

let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { useActionAvailable } = require("%ui/hud/state/actions_state.nut")
let { requestAmmoTimeout } = require("%ui/hud/state/requestAmmoState.nut")
let { secondsToString } = require("%ui/helpers/time.nut")
let { ACTION_REQUEST_AMMO } = require("hud_actions")

let actions = {
  [ACTION_REQUEST_AMMO] = { hintText = @(time) loc("hud/ammo_requst_cooldown", "Ammo requst cooldown: {time} left", {time = time}) },
}

return function () {
  local tip = null

  let action = actions?[useActionAvailable.value]
  if (requestAmmoTimeout.value > 0 && action != null) {
    tip = tipCmp({
      text = action.hintText(secondsToString(requestAmmoTimeout.value))
      textColor =  DEFAULT_TEXT_COLOR
    })
  }

  return {
    watch = [
      requestAmmoTimeout
    ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = tip
  }
}