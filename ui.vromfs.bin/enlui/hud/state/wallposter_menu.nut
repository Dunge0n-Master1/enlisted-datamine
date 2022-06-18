from "%enlSqGlob/ui_library.nut" import *

let wallposterMenuItems = mkWatched(persist, "items", [])
let radius = Computed(@() hdpx(365))
let elemSize = Computed(@() array(2, (radius.value * 0.35).tointeger()))
let showWallposterMenu = mkWatched(persist, "showWallposterMenu", false)

return {
  wallposterMenuItems
  radius
  elemSize
  showWallposterMenu
}
