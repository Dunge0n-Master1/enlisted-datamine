from "%enlSqGlob/ui_library.nut" import *

let checkbox = require("%ui/components/checkbox.nut")
let localSettings = require("%enlist/options/localSettings.nut")("quickMatch/")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")


let isDetailsFull = localSettings(false, "isDetailsFull")

let detailsModeCheckbox = checkbox(isDetailsFull, {
    text = loc("showDetails")
    color = titleTxtColor
  }.__update(fontSub), {
    setValue = @(val) isDetailsFull(val)
    textOnTheLeft = true
    override = { hotkeys = [["^J:Start", { description = loc("showDetails") } ]]}
  }
)

return {
  isDetailsFull
  detailsModeCheckbox
}
