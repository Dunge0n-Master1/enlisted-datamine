from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")

let noInfoHeight = hdpxi(35)
let withInfoHeight = hdpxi(55)
let padding = hdpx(10)

let function mkBoosterMark(expMul, infoText = null, override = {}) {
  let isEmptyInfo = (infoText ?? "") == ""
  let height = isEmptyInfo ? noInfoHeight : withInfoHeight
  let offs = [0, (0.3 * height).tointeger(), 0, (0.1 * height).tointeger()]
  return {
    size = [SIZE_TO_CONTENT, height]
    padding = [0, 0.2 * height + padding, 0, padding]
    rendObj = ROBJ_9RECT
    image = Picture($"!ui/skin#booster_bg.svg:{(1.1 * height + 0.5).tointeger()}:{height}?Ac")
    texOffs = offs
    screenOffs = offs

    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER

    children = [
      {
        rendObj = ROBJ_TEXT
        color = 0xFFB5E1CF
        text = loc("expBoost", { boost = (100.0 * expMul + 0.5).tointeger() })
      }.__update(sub_txt)
      isEmptyInfo ? null
        : {
            rendObj = ROBJ_TEXT
            color = 0xFF2B4637
            text = infoText
          }.__update(tiny_txt)
      { size = [0, 0.1 *height] } //bottom padding does not work with valign, but need offset for shadow
    ]
  }.__update(override)
}

return mkBoosterMark
