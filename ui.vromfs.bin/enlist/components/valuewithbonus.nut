from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor, titleTxtColor, bonusColor } = require("%enlSqGlob/ui/viewConst.nut")
let { note } = require("%enlSqGlob/ui/defcomps.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")

let trim = @(str) "".join((str ?? "").tostring().split())

let function strikeThrough(child) {
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_COLOR, defTxtColor],
      [VECTOR_LINE, 0, 90, 100, 20]
    ]
    padding = [0, hdpx(5)]
    margin = [0, hdpx(5), 0, 0]
    children = child
  }
}

let function mkValueWithBonus(commonValue, bonusValue, style = {}) {
  let commonWatch = commonValue instanceof Watched ? commonValue : Computed(@() commonValue)
  let bonusWatch = bonusValue instanceof Watched ? bonusValue : Computed(@() bonusValue)
  let watches = [commonWatch, bonusWatch]
  return @() bonusWatch.value != null
    ? {
        watch = watches
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          strikeThrough(note(trim(commonWatch.value)).__update(style))
          premiumImage(hdpx(20), { pos = [0, hdpx(2)] })
          note({ text = trim(bonusWatch.value), color = bonusColor })
            .__update(style)
        ]
      }
    : note({ watch = watches, text = trim(commonWatch.value), color = titleTxtColor })
        .__update(style)
}

return mkValueWithBonus