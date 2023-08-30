from "%enlSqGlob/ui_library.nut" import *

let {fontHeading2, fontSub} = require("%enlSqGlob/ui/fontsStyle.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")

local function textarea(txt, params={}) {
  if (type(txt)=="table") {
    params = txt
    txt = params?.text
  }
  return {
    size = [flex(), SIZE_TO_CONTENT]
    color = DEFAULT_TEXT_COLOR
    text = txt
  }.__update(fontHeading2, params, {
    rendObj=ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
  })
}
local function smallTextarea(txt, params={}) {
  if (type(txt)=="table")
    txt = params?.text ?? ""
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_LEFT
    rendObj=ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text=txt
  }.__update(fontSub, params)
}


return {
  textarea
  smallTextarea
}