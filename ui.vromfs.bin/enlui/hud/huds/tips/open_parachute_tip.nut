from "%enlSqGlob/ui_library.nut" import *

let { isAlive } = require("%ui/hud/state/health_state.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let { canOpenParachute, isParachuteOpened } = require("%ui/hud/state/parachute_state.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")

let deployTip = tipCmp({
  inputId = "Human.Jump"
  text = loc("tips/open_parachute")
  textColor = Color(100,140,200,110)
})

let showTip = Computed(@()
  showPlayerHuds.value
  && canOpenParachute.value
  && !isParachuteOpened.value
  && isAlive.value)

return @() {
  watch = showTip
  size = SIZE_TO_CONTENT
  children = showTip.value ? deployTip : null
}
