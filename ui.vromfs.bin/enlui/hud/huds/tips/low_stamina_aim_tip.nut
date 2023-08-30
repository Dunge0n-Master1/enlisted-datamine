from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { staminaCanAim } = require("%ui/hud/state/stamina_es.nut")
let { isAimPressed } = require("%ui/hud/huds/crosshair_state_es.nut")

let tip = tipCmp({
  text = loc("tips/staminaTooLowToAim"),
  textColor = DEFAULT_TEXT_COLOR,
}.__update(fontBody))

return @() {
  flow = FLOW_HORIZONTAL
  watch = [staminaCanAim, isAimPressed]
  children = (!staminaCanAim.value && isAimPressed.value) ? tip : null
}
