from "%enlSqGlob/ui_library.nut" import *

let mkToggle = require("%ui/components/mkToggle.nut")
let checkbox = require("%ui/components/checkbox.nut")
let localSettings = require("%enlist/options/localSettings.nut")("quickMatch/")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { smallPadding } = require("%enlSqGlob/ui/designConst.nut")


let isDetailsFull = localSettings(false, "isDetailsFull")

let detailsModeCheckbox = checkbox(isDetailsFull, {
    text = loc("showDetails")
    color = titleTxtColor
  }.__update(sub_txt), {
    setValue = @(val) isDetailsFull(val)
    textOnTheLeft = true
    override = { hotkeys = [["^J:Start", { description = loc("showDetails") } ]]}
  }
)

let detalsModeSwitch = {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("showDetails")
    }
    mkToggle(isDetailsFull)
  ]
}

return {
  isDetailsFull
  detalsModeSwitch
  detailsModeCheckbox
}
