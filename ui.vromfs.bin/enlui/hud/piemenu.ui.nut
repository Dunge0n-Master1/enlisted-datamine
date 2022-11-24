from "%enlSqGlob/ui_library.nut" import *

let mkPieMenu = require("%ui/components/mkPieMenuHoldable.nut")
let {
  showPieMenu, pieMenuLayer, curPieMenuItems, radius, elemSize
} = require("%ui/hud/state/pie_menu_state.nut")
let { pieMenuNavigation } = require("%ui/hud/components/piemenu_navigation.nut")
let { canUseWallposter } = require("%ui/hud/state/wallposters_use_state.nut")


let pieMenu = mkPieMenu({
  actions = curPieMenuItems,
  showPieMenu = showPieMenu
  radius = radius,
  elemSize = elemSize,
  key = "pieMenu"
})

canUseWallposter.subscribe(@(val) !val ? pieMenuLayer.value == 0 ? pieMenuLayer(1) : null : null)

return {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    pieMenu
    pieMenuNavigation
  ]
  key = "pieMenuTabs"
}
