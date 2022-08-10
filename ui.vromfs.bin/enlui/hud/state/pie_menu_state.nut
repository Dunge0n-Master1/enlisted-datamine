from "%enlSqGlob/ui_library.nut" import *

let pieMenuItems = mkWatched(persist, "items", [], FRP_DONT_CHECK_NESTED)
let radius = hdpx(390)

let showPieMenu = mkWatched(persist, "showPieMenu", false)
let openPath = mkWatched(persist, "openPath", [])
let path = mkWatched(persist, "path", [])

let mkNextPathItem = @(item) {
  text = loc(item?.id ?? "")
  closeOnClick = false
  action = @() path.mutate(@(p) p.append(item?.id ?? ""))
  available = Watched(true)
}.__update(item)

let curPieMenuItems = Computed(function() {
  local list = pieMenuItems.value
  foreach (id in path.value) {
    list = list.findvalue(@(p) p?.id == id)?.items
    if (type(list) != "array")
      return [] //no items by path
  }
  return list.map(@(item) type(item?.items) == "array" ? mkNextPathItem(item) : item)
}, FRP_DONT_CHECK_NESTED)

openPath.subscribe(@(v) path(clone v))
showPieMenu.subscribe(@(v) v ? null : openPath([]))

return {
  pieMenuItems
  openPieMenuPath = openPath
  pieMenuPath = path
  radius = Watched(radius)
  elemSize = Watched([(radius*0.35).tointeger(),(radius*0.35).tointeger()])
  showPieMenu
  curPieMenuItems
}
