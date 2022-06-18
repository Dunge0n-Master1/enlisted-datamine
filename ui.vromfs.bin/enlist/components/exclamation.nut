from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let faComp = require("%ui/components/faComp.nut")

let infoText = @(text) {
  size = SIZE_TO_CONTENT
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(sub_txt)

let exclamation = @(text = "") {
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    faComp("exclamation-triangle", { color = defTxtColor, fontSize = sub_txt.fontSize })
    text == "" ? null : infoText(text)
  ]
}

return exclamation
