from "%enlSqGlob/ui_library.nut" import *

let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")

let buildingToolMenuItems = mkWatched(persist, "items", [], FRP_DONT_CHECK_NESTED)
let radius = Computed(@() isTutorial.value ? hdpx(320) : hdpx(365))
let elemSize = Computed(@() array(2, (radius.value * 0.3).tointeger()))

let showBuildingToolMenu = mkWatched(persist, "showBuildingToolMenu", false)
let openPath = mkWatched(persist, "openPath", [])
let path = mkWatched(persist, "path", [])

let mkNextPathItem = @(item) item.__merge({
  text = loc(item?.id ?? "")
  closeOnClick = false
  action = @() path.mutate(@(p) p.append(item?.id ?? ""))
  available = Watched(true)
})

let curBuildingToolMenuItems = Computed(function() {
  local list = buildingToolMenuItems.value
  foreach (id in path.value) {
    list = list.findvalue(@(p) p?.id == id)?.items
    if (type(list) != "array")
      return [] //no items by path
  }
  return list.map(@(item) type(item?.items) == "array" ? mkNextPathItem(item) : item)
}, FRP_DONT_CHECK_NESTED)

openPath.subscribe(@(v) path(clone v))
showBuildingToolMenu.subscribe(@(v) v ? null : openPath([]))

return {
  buildingToolMenuItems
  openBuildingToolMenuPath = openPath
  buildingToolMenuPath = path
  radius
  elemSize
  showBuildingToolMenu
  curBuildingToolMenuItems
}
