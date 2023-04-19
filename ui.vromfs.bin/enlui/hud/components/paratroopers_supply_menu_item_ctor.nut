from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")

let mkText = @(slot) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc(slot?.text ?? "")
  color = DEFAULT_TEXT_COLOR
  indent = hdpx(5)
  transform = {}
}.__update(sub_txt)

return @(slot) function(...) {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    children = mkText(slot)
  }
}
