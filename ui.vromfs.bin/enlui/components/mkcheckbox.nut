from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { activeBgColor, commonBorderRadius, panelBgColor, defBdColor, disabledBgColor
} = require("%enlSqGlob/ui/designConst.nut")

let smallBox = @(isChecked, isActive = true, canBeModified = true) watchElemState(@(sf) {
  watch = isChecked
  rendObj = ROBJ_BOX
  borderWidth = isActive && ((sf & S_HOVER) || isChecked.value) ? hdpx(1) : 0
  borderRadius = commonBorderRadius * 2
  borderColor = isActive ? activeBgColor : defBdColor
  padding = hdpx(4)
  behavior = Behaviors.Button
  onClick = @() isActive && canBeModified ? isChecked(!isChecked.value) : null
  children = {
    size = [fontSmall.fontSize, fontSmall.fontSize]
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    borderRadius = commonBorderRadius
    borderColor = isActive ? activeBgColor : defBdColor
    fillColor = !isActive ? disabledBgColor
      : isChecked.value ? activeBgColor
      : panelBgColor
  }
})

return smallBox