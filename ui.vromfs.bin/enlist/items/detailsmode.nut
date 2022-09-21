from "%enlSqGlob/ui_library.nut" import *

local checkbox = require("%ui/components/checkbox.nut")
local localSettings = require("%enlist/options/localSettings.nut")("quickMatch/")
local { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
local { titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")


local isDetailsFull = localSettings(false, "isDetailsFull")

local detailsModeCheckbox = checkbox(isDetailsFull, {
    text = loc("showDetails")
    color = titleTxtColor
  }.__update(sub_txt), {
    setValue = @(val) isDetailsFull(val)
    textOnTheLeft = true
  }
)

return {
  isDetailsFull
  detailsModeCheckbox
}
