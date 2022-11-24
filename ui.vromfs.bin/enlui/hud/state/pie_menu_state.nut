from "%enlSqGlob/ui_library.nut" import *

// currently main pie menu has three "layers" 0 - posters, 1 - default; bot commands, 3 - quick chat
// we can switch between them using shortcuts without menu closing
let DEFAULT_LAYER = 1
let pieMenuAllLayersItems = mkWatched(persist, "items", [], FRP_DONT_CHECK_NESTED)
let pieMenuLayer = Watched(DEFAULT_LAYER)
let showPieMenu = mkWatched(persist, "showPieMenu", false)
let radius = hdpx(390)

let curPieMenuItems = Computed(@() pieMenuAllLayersItems.value?[pieMenuLayer.value] ?? [], FRP_DONT_CHECK_NESTED)

// reset to default layer on pie menu close
showPieMenu.subscribe(@(_val) pieMenuLayer(DEFAULT_LAYER))

return {
  pieMenuItems = pieMenuAllLayersItems
  pieMenuLayer
  curPieMenuItems
  radius = Watched(radius)
  elemSize = Watched([(radius*0.35).tointeger(),(radius*0.35).tointeger()])
  showPieMenu
}
