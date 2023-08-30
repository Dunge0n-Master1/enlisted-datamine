from "%enlSqGlob/ui_library.nut" import *
let { FAButton } = require("%ui/components/txtButton.nut")
let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")


let changeButtonStyle = {
  size = [hdpxi(48), hdpxi(48)]
  margin = 0
}

let tb = @(key, action) @() {
  watch = isGamepad
  isHidden = !isGamepad.value
  vplace = ALIGN_CENTER
  children = mkHotkey(key, action)
}

let function mkCounter(maxCount, countWatched, step = 1) {
  let decCount = @() countWatched.value > step ? countWatched(countWatched.value - step) : null
  let incCount = @()
    countWatched.value + step <= maxCount ? countWatched(countWatched.value + step) : null

  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      tb("^J:LB", decCount)
      FAButton("minus", decCount, changeButtonStyle)
      @() {
        rendObj = ROBJ_TEXT
        watch = countWatched
        fontSize = hdpx(30)
        minWidth = hdpx(40)
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        margin = [0, smallPadding]
        text = countWatched.value
      }.__update(fontHeading2)
      FAButton("plus", incCount, changeButtonStyle)
      tb("^J:RB",  incCount)
    ]
  }
}

return {
  mkCounter
}