from "%enlSqGlob/ui_library.nut" import *

let { isAlive } = require("%ui/hud/state/health_state.nut")
let { isAiming } = require("%ui/hud/huds/crosshair_state_es.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")

let tip = tipCmp({
  inputId = "HUD.SetMark"
  text = loc("controls/HUD.SetMark")
  textColor = Color(200,140,100,110)
})

let isPreventReloadingVisible = Computed(@() isAiming.value && isAlive.value)

return @() {
  watch = isPreventReloadingVisible
  size = SIZE_TO_CONTENT
  children = isPreventReloadingVisible.value ? tip : null
}
