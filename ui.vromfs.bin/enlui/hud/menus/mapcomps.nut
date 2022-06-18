from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let uiHotkeysHint = require("%ui/components/uiHotkeysHint.nut").mkHintRow
let formatInputBinding = require("%ui/control/formatInputBinding.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { shadowStyle } = require("%enlSqGlob/ui/viewConst.nut")

let hintTextFunc = @(text, color = DEFAULT_TEXT_COLOR) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(body_txt, shadowStyle)

let function mkTips(keys, locId){
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = formatInputBinding.buildElems(keys, { textFunc = hintTextFunc })
      .append(hintTextFunc(loc(locId)))
  }
}

let function makeHintRow(hotkeys, text) {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [uiHotkeysHint(hotkeys,{textFunc=hintTextFunc})].append(hintTextFunc(text))
  }
}

let mouseNavTips = mkTips(["MMB"], "map/bigMapPan")
let placePointsTipGamepad = {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    makeHintRow(JB.A, loc("map/place_marks/gamepad"))
  ]
}
let navGamepadHints = {
  flow = FLOW_HORIZONTAL
  gap = fsh(5)
  children = [
    mkTips(["J:LT", "J:RT"], "map/zoom")
    mkTips(["J:R.Thumb.hv"], "map/bigMapPan")
  ]
}

let placePointsTipMouse = mkTips(["RMB"], "map/place_marks/gamepad")

return {hintTextFunc, mouseNavTips, placePointsTipGamepad, navGamepadHints, mkTips, makeHintRow, placePointsTipMouse}
