from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  activeTxtColor, titleTxtColor, defTxtColor, tinyOffset, smallPadding,
  bigPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallUnseenNoBlink, unseenByType } = require("%ui/components/unseenComps.nut")
let { soundDefault } = require("%ui/components/textButton.nut")



let function mkUnseenSign(mark, isSelected) {
  let sign = unseenByType?[mark]
  return sign == null ? null
    : isSelected ? smallUnseenNoBlink
    : sign
}

let function txtColor (sf){
  return sf & S_ACTIVE ? activeTxtColor
    : sf & S_HOVER ? titleTxtColor
    : defTxtColor
}

let mkTabText = @(text, color) type(text) == "function" ? text(color)
  : { rendObj = ROBJ_TEXT, color, text }.__update(h2_txt)

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
      borderColor = txtColor(sf)
      children = [
        {
          padding = [0, 0, tinyOffset, 0]
          children = mkTabText(text, isSelected ? activeTxtColor : txtColor(sf))
        }
        {
          pos = [tinyOffset, -bigPadding]
          hplace = ALIGN_RIGHT
          children = mkUnseenSign(unseenMarkType.value, isSelected)
        }
      ]
    }
  }.__update(override))

return mkWindowTab
