from "%enlSqGlob/ui_library.nut" import *

let { setInteractiveElement } = require("%ui/hud/state/interactive_state.nut")
let mkPieMenu = require("%ui/components/mkPieMenu.nut")
let {
  showPieMenu, curPieMenuItems, radius, elemSize, openPieMenuPath, pieMenuPath
} = require("state/pie_menu_state.nut")

showPieMenu.subscribe(@(val) setInteractiveElement("pieMenu", val))

let pieMenu = mkPieMenu({
  actions = curPieMenuItems,
  showPieMenu = showPieMenu
  radius = radius,
  elemSize = elemSize,
  close = @() openPieMenuPath.value.len() >= pieMenuPath.value.len()
    ? showPieMenu(false)
    : pieMenuPath.mutate(@(p) p.remove(p.len() - 1))
})

return {
  size = flex()
  children = pieMenu
  key = "pieMenuTabs"
}
