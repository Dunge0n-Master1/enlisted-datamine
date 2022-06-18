from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let {
  defTxtColor, selectedTxtColor, defInsideBgColor, activeBgColor,
  blurBgFillColor, titleTxtColor, disabledTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")


let PROFILE_WIDTH = fsh(100)

let DEFAULT_FOOTER_PARAMS = {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_HORIZONTAL
}

let txtColor = @(sf, isSelected = false) isSelected ? selectedTxtColor
    : sf & S_HOVER ? titleTxtColor
    : defTxtColor

let bgColor = @(sf, isSelected = false) isSelected ? activeBgColor
  : sf & S_HOVER ? defInsideBgColor
  : blurBgFillColor

let borderColor = @(sf, isSelected = false) isSelected ? activeBgColor
  : sf & S_HOVER ? activeBgColor
  : disabledTxtColor

let mkFooterWithButtons = @(buttonsList, params = DEFAULT_FOOTER_PARAMS) {
  children = buttonsList
}.__merge(params)

let mkFooterWithBackButton = @(onClick, params = DEFAULT_FOOTER_PARAMS)
  mkFooterWithButtons([
    Bordered(loc("BackBtn"), onClick, {
      margin = 0
      hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
    })
  ], params)

return {
  mkFooterWithBackButton,
  mkFooterWithButtons
  txtColor
  bgColor
  borderColor

  PROFILE_WIDTH
}
