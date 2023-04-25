from "%enlSqGlob/ui_library.nut" import *

let mkPieMenu = require("%ui/components/mkPieMenuHoldable.nut")
let {
  showBuildingToolMenu, curBuildingToolMenuItems, radius, elemSize
} = require("%ui/hud/state/building_tool_menu_state.nut")

let buildingToolMenu = mkPieMenu({
  actions = curBuildingToolMenuItems,
  showPieMenu = showBuildingToolMenu
  radius = radius,
  elemSize = elemSize,
})

return {
  size = flex()
  children = buildingToolMenu
  key = "buildMenuMenuTabs"
}
