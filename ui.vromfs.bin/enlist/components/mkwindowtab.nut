from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  activeTxtColor, titleTxtColor, defTxtColor, tinyOffset, smallPadding,
  bigPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")(0.7)


let function txtColor (sf){
  return sf & S_ACTIVE ? activeTxtColor
    : sf & S_HOVER ? titleTxtColor
    : defTxtColor
}

let mkTabText = @(text, color) type(text) == "function" ? text(color)
  : { rendObj = ROBJ_TEXT, color, text }.__update(h2_txt)

let mkWindowTab = @(text, onClick, isSelected, isUnseen = Watched(false), customStyle = {})
  watchElemState(@(sf) {
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    sound = {
      click  = "ui/enlist/button_click"
      hover  = "ui/enlist/button_highlight"
    }
    onClick
    children = @() {
      watch = isUnseen
      rendObj = ROBJ_BOX
      borderWidth = isSelected ? [0, 0, smallPadding, 0] : 0
      borderColor = txtColor(sf)
      children = [
        {
          padding = [0, 0, tinyOffset, 0]
          children = mkTabText(text, isSelected ? activeTxtColor : txtColor(sf))
        }
        !isUnseen.value ? null
          : unseenSignal.__update({
              pos = [tinyOffset, -bigPadding]
              hplace = ALIGN_RIGHT
            })
      ]
    }
  }.__update(customStyle))

return mkWindowTab
