from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { canHealSelectedSoldier } = require("%ui/hud/state/medic_state.nut")


let tip = tipCmp({
  text = loc("medic/heal_player"),
  textColor = DEFAULT_TEXT_COLOR,
  inputId = "Human.Use"
}.__update(body_txt))

return @() {
  flow = FLOW_HORIZONTAL
  watch = [canHealSelectedSoldier]
  children = canHealSelectedSoldier.value ? tip : null
}
