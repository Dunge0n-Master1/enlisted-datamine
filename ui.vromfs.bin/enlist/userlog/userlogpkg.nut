from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { defTxtColor, activeBgColor, smallOffset, disabledTxtColor, smallPadding, bigPadding,
  tinyOffset, accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")


let borderColor = @(sf, isSelected = false) isSelected ? activeBgColor
  : sf & S_HOVER ? activeBgColor
  : disabledTxtColor

let rowStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = tinyOffset
  valign = ALIGN_CENTER
}

let mkRowText = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(sub_txt)

let userLogStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  padding = bigPadding
  gap = smallPadding
  halign = ALIGN_CENTER
}

let userLogRowStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  padding = [tinyOffset, smallOffset]
}

let mkUserLogHeader = @(isSelected, logTime, logText) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = [smallOffset, flex()]
      halign = ALIGN_CENTER
      children = faComp(isSelected ? "caret-right" : "caret-down",
        { color = disabledTxtColor })
    }
    txt({
      text = logText
      size = [flex(), SIZE_TO_CONTENT]
      color = accentTitleTxtColor
    }).__update(sub_txt)
    // TODO: Need convert uLog.logTime to date format
    txt({
      text = logTime
      color = defTxtColor
    }).__update(sub_txt)
  ]
}

return {
  borderColor
  rowStyle
  userLogStyle
  userLogRowStyle

  mkRowText
  mkUserLogHeader
}
