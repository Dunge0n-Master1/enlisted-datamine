from "%enlSqGlob/ui_library.nut" import *

//let faComp = require("%ui/components/faComp.nut")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { smallOffset,
  tinyOffset, accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { defTxtColor, darkTxtColor, smallPadding, bigPadding } = require("%enlSqGlob/ui/designConst.nut")
let { format_unix_time } = require("dagor.iso8601")


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
}.__update(fontSub)

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

//let selected = faComp("caret-right", { color = disabledTxtColor })
//let not_selected = faComp("caret-down", { color = disabledTxtColor })
let mkUserLogHeader = @(_isSelected, logTime, logText, sf) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
/*    {
      size = [smallOffset, flex()]
      halign = ALIGN_CENTER
      children = isSelected ? selected : not_selected
    }
*/
    txt({
      text = logText
      size = [flex(), SIZE_TO_CONTENT]
      color = sf & S_HOVER ? darkTxtColor : accentTitleTxtColor
    }).__update(fontSub)
    txt({
      text = format_unix_time(logTime).replace("T", " ").replace("Z", "")
      color = sf & S_HOVER ? darkTxtColor : defTxtColor
    }).__update(fontSub)
  ]
}

return {
  rowStyle
  userLogStyle
  userLogRowStyle

  mkRowText
  mkUserLogHeader
}
