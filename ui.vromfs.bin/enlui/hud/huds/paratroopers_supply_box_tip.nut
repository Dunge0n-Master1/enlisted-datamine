from "%enlSqGlob/ui_library.nut" import *


let {showParatroopersSupplyBoxTip} = require("%ui/hud/state/paratroopers_supply_box_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")


let function paratroopers_supply_box_tip() {
  let res = { watch = showParatroopersSupplyBoxTip }
  if (!showParatroopersSupplyBoxTip.value)
    return res
  return res.__update({
    size = SIZE_TO_CONTENT
    children = tipCmp({
      text = loc("hud/use_paratroopers_supply_box")
      inputId = "Human.SupplyMenu"
    })
  })
}


return paratroopers_supply_box_tip
