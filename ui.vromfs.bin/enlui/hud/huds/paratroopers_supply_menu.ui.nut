from "%enlSqGlob/ui_library.nut" import *

let mkPieMenu = require("%ui/components/mkPieMenuHoldable.nut")
let {
  showSupplyMenu, squadSupplyMenuItems, selectedSupplyMenuItemIdx, radius, elemSize
} = require("%ui/hud/state/paratroopers_supply_menu_state.nut")

let menu = mkPieMenu({
  actions = squadSupplyMenuItems,
  curIdx = selectedSupplyMenuItemIdx,
  showPieMenu = showSupplyMenu
  radius = radius,
  elemSize = elemSize,
  stickNo = 0
})

return {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = menu
  key = "paratroopersSupplyMenuTabs"
}
