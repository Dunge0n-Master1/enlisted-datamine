from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  bigPadding, defInsideBgColor, defTxtColor, blurBgFillColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  rowHeight
} = require("%enlist/gameModes/eventModeStyle.nut")

let setColorBySF = @(sf) sf & S_HOVER ? defInsideBgColor : blurBgFillColor

let mkOptionRow = function (locId, component = null, override = {},
  onClick = @() null, firstChild = null
) {
  let stateFlag = Watched(0)
  return @() {
    watch = stateFlag
    size = [flex(), rowHeight]
    rendObj = ROBJ_SOLID
    behavior = Behaviors.Button
    onClick
    color = setColorBySF(stateFlag.value)
    onElemState = @(v) stateFlag(v)
    margin = [smallPadding, 0]
    padding = [0, bigPadding]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      firstChild
      {
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        size = flex()
        valign = ALIGN_CENTER
        color = defTxtColor
        text = locId == null ? null : loc(locId)
      }.__update(body_txt)
      component
    ]
  }.__update(override)
}

return mkOptionRow