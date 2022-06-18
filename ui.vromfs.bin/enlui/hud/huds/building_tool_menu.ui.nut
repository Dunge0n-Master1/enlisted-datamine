from "%enlSqGlob/ui_library.nut" import *

let {setInteractiveElement} = require("%ui/hud/state/interactive_state.nut")
let mkPieMenu = require("%ui/components/mkPieMenu.nut")
let {
  showBuildingToolMenu, curBuildingToolMenuItems, radius, elemSize,
  openBuildingToolMenuPath, buildingToolMenuPath
} = require("%ui/hud/state/building_tool_menu_state.nut")

showBuildingToolMenu.subscribe(@(val) setInteractiveElement("BuildingToolMenu", val))

let buildingToolMenu = mkPieMenu({
  actions = curBuildingToolMenuItems,
  showPieMenu = showBuildingToolMenu
  radius = radius,
  elemSize = elemSize,
  close = @() openBuildingToolMenuPath.value.len() >= buildingToolMenuPath.value.len()
    ? showBuildingToolMenu(false)
    : buildingToolMenuPath.mutate(@(p) p.remove(p.len() - 1))
})

return {
  size = flex()
  children = buildingToolMenu
  key = "buildMenuMenuTabs"
}
