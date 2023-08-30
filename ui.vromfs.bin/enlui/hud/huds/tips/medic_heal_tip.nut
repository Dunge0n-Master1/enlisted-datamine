from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { canHealSelectedSoldier } = require("%ui/hud/state/medic_state.nut")


let tip = tipCmp({
  text = loc("medic/heal_player"),
  textColor = DEFAULT_TEXT_COLOR,
  inputId = "Human.Use"
}.__update(fontBody))

return @() {
  flow = FLOW_HORIZONTAL
  watch = [canHealSelectedSoldier]
  children = canHealSelectedSoldier.value ? tip : null
}
