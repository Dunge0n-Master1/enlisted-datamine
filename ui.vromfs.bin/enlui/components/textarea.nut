from "%enlSqGlob/ui_library.nut" import *

let {h2_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
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
  }.__update(h2_txt, params, {
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
  }.__update(sub_txt, params)
}


return {
  textarea
  smallTextarea
}