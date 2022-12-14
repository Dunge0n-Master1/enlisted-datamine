from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { radius } = require("%ui/hud/state/building_tool_menu_state.nut")
let {
  availableBuildings, buildingLimits , requirePrice, availableStock, buildingAllowRecreates
} = require("%ui/hud/state/building_tool_state.nut")

let white = Color(255,255,255)
let dark = Color(200,200,200)
let disableColor = Color(60,60,60)
let disabledTextColor = Color(50, 50, 50, 50)
let curTextColor = Color(250,250,200,200)
let defTextColor = Color(150,150,150,50)

return @(buildingIndex, image, imageSize) @(curIdx, idx) watchElemState(function(sf) {
  let count = availableBuildings.value?[buildingIndex] ?? 0
  let limit = buildingLimits.value?[buildingIndex] ?? 0
  let allowRecreate = buildingAllowRecreates.value?[buildingIndex] ?? false
  let available = (allowRecreate || count > 0) && (requirePrice.value[buildingIndex] <= availableStock.value)
  let isCurrent = (sf & S_HOVER) || curIdx == idx
  let icon = image ? {
    image = Picture(image)
    rendObj = ROBJ_IMAGE
    size = imageSize
    color = !available ? disableColor : isCurrent ? white : dark
  } : null
  let text = {
    rendObj = ROBJ_TEXT
    color = !available ? disabledTextColor
              : isCurrent ? curTextColor
              : defTextColor
    text = "{count}/{limit}".subst({count=count limit=limit})
  }.__update(body_txt)

  return {
    watch = [availableBuildings]
    children = [
      icon
      text
    ]
    size = array(2, (0.4 * radius.value).tointeger())
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
  }
})