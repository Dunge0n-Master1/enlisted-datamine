from "%enlSqGlob/ui_library.nut" import *

let {TextDefault, statusIconBg} = require("%ui/style/colors.nut")
let faComp = require("%ui/components/faComp.nut")

let emptyGap = {
  size = [fsh(1), fsh(1)]
}

let horGap = {
  size = [fsh(3), flex()], halign = ALIGN_CENTER, valign = ALIGN_CENTER
  children = { rendObj = ROBJ_SOLID, size = [hdpx(1),flex()], color = TextDefault, margin = [hdpx(4),0], opacity = 0.5 }
}

let ICON_IN_CIRCLE_DEFAULTS = { fontSize = hdpx(20) }

local function iconInCircle(iconParams = ICON_IN_CIRCLE_DEFAULTS) {
  iconParams = ICON_IN_CIRCLE_DEFAULTS.__merge(iconParams)
  let children = iconParams?.faIcon ? faComp(iconParams?.faIcon, iconParams) : faComp(iconParams)
  let fontSize = iconParams?.fontSize ?? calc_comp_size(children).reduce(@(a,b) max(a,b))
  return faComp("circle", {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    fontSize = fontSize * 1.3
    color = statusIconBg
    children
  })
}

let function compInCircle(comp) {
  let fontSize = calc_comp_size(comp).reduce(@(a,b) max(a,b))
  return faComp("circle", {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = statusIconBg
    children = comp
    fontSize
  })
}

return {
  horGap
  emptyGap
  iconInCircle
  compInCircle
}
