from "%enlSqGlob/ui_library.nut" import *

let {setInteractiveElement} = require("%ui/hud/state/interactive_state.nut")
let mkPieMenu = require("%ui/components/mkPieMenu.nut")
let { showWallposterMenu, wallposterMenuItems, radius, elemSize } = require("%ui/hud/state/wallposter_menu.nut")

showWallposterMenu.subscribe(@(val) setInteractiveElement("WallposterMenu", val))

let wallposterMenu = mkPieMenu({
  actions = wallposterMenuItems,
  showPieMenu = showWallposterMenu
  radius = radius,
  elemSize = elemSize,
  close = @() showWallposterMenu(false)
})

return {
  size = flex()
  children = wallposterMenu
  key = "wallposterMenuMenuTabs"
}
