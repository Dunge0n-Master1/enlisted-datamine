from "%enlSqGlob/ui_library.nut" import *
let { Bordered } = require("%ui/components/textButton.nut")
let { h2_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let { smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let fa = require("%ui/components/fontawesome.map.nut")

let changeButtonStyle = {
  size = [hdpx(40),hdpx(40)]
  margin = 0
  fontSize = hdpx(15)
  font = fontawesome.font
}

let tb = @(key, action) @() {
  watch = isGamepad
  isHidden = !isGamepad.value
  vplace = ALIGN_CENTER
  children = mkHotkey(key, action)
}

let function mkCounter(maxCount, countWatched) {
  let decCount = @() countWatched.value > 1 ? countWatched(countWatched.value - 1) : null
  let incCount = @() countWatched.value < maxCount ? countWatched(countWatched.value + 1) : null

  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      tb("^J:LB", decCount)
      Bordered(fa["minus"], decCount, changeButtonStyle)
      @() {
        rendObj = ROBJ_TEXT
        watch = countWatched
        fontSize = hdpx(30)
        minWidth = hdpx(40)
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        text = countWatched.value
      }.__update(h2_txt)
      Bordered(fa["plus"], incCount, changeButtonStyle)
      tb("^J:RB",  incCount)
    ]
  }
}

return {
  mkCounter
}