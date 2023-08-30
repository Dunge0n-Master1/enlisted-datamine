from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let {
  activeTxtColor, tinyOffset
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallPadding, bigPadding, defTxtColor,
  hoverSlotBgColor, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")

let { smallUnseenNoBlink, unseenByType } = require("%ui/components/unseenComps.nut")
let { soundDefault } = require("%ui/components/textButton.nut")



let function mkUnseenSign(mark, isSelected) {
  let sign = unseenByType?[mark]
  return sign == null ? null
    : isSelected ? smallUnseenNoBlink
    : sign
}

let function txtColor(sf, isSelected=true){
  return sf & S_ACTIVE
    ? activeTxtColor
    : sf & S_HOVER
      ? darkTxtColor
      : isSelected
        ? activeTxtColor
        : defTxtColor
}

let mkTabText = @(text, color) type(text) == "function" ? text(color)
  : { rendObj = ROBJ_TEXT, color, text }.__update(fontHeading2)

let mkWindowTab = @(text, onClick, isSelected, override = {}, unseenMarkType = Watched(null))
  watchElemState(@(sf) {
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    sound = soundDefault
    onClick
    children = @() {
      watch = [unseenMarkType]
      rendObj = ROBJ_BOX
      borderWidth = isSelected ? [0, 0, smallPadding, 0] : 0
      fillColor = sf & S_HOVER ? hoverSlotBgColor : 0
      padding = tinyOffset
      borderColor = Color(255,255,255)
      children = [
        mkTabText(text, txtColor(sf, isSelected))
        {
          pos = [tinyOffset, -bigPadding]
          hplace = ALIGN_RIGHT
          children = mkUnseenSign(unseenMarkType.value, isSelected)
        }
      ]
    }
  }.__update(override))

return mkWindowTab
