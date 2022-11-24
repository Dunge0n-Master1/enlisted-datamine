from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")

let white = Color(255,255,255)
let dark = Color(200,200,200)
let curTextColor = Color(250,250,200,200)
let defTextColor = Color(150,150,150,50)
let menuSize = array(2, (0.4 * hdpx(390)).tointeger())

return @(_buildingIndex, image, hintText) @(curIdx, idx) watchElemState(function(sf) {
  let isCurrent = (sf & S_HOVER) || curIdx == idx

  let icon = image ? {
    image = Picture(image)
    rendObj = ROBJ_IMAGE
    color = isCurrent ? white : dark
  } : null
  let text = {
    rendObj = ROBJ_TEXT
    color = isCurrent ? curTextColor : defTextColor
    text = hintText
  }.__update(sub_txt)

  return {
    size = menuSize
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      icon
      text
    ]
  }
})