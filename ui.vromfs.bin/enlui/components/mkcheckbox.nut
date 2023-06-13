from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, commonBorderRadius, panelBgColor, disabledBdColor, disabledBgColor, colPart,
  disabledTxtColor, midPadding
} = require("%enlSqGlob/ui/designConst.nut")
let faComp = require("%ui/components/faComp.nut")


let mkLabel = @(label, size, textParams, isActive, isLeftOrientation = true) {
  rendObj = ROBJ_TEXTAREA
  size
  behavior = Behaviors.TextArea
  text = label
  halign = isLeftOrientation ? ALIGN_RIGHT : ALIGN_LEFT
}.__update(textParams, !isActive ? { color = disabledTxtColor } : {})


let checkBox = @(isChecked, isActive, isHovered) {
  size = [colPart(0.29), colPart(0.29)]
  rendObj = ROBJ_BOX
  borderWidth = isHovered ? hdpx(2) : hdpx(1)
  borderRadius = commonBorderRadius * 2
  borderColor = isActive ? accentColor : disabledBdColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = isActive ? panelBgColor : disabledBgColor
  children = !isChecked ? null : faComp("check", {
    color = accentColor
    fontSize = colPart(0.19)
  })
}


let function mkCheckbox(isChecked, label, params = {}) {
  let { canBeModified = true, isActive = true, size = [flex(), SIZE_TO_CONTENT],
    isLeftOrientation = true, onClick = null, textParams = fontSmall, blockParams = {}
  } = params

  let defAction = @() isChecked(!isChecked.value)
  return watchElemState(@(sf) {
    watch = isChecked
    size
    behavior = Behaviors.Button
    onClick = !isActive ? null
      : canBeModified ? onClick ?? defAction
      : !canBeModified && onClick != null ? onClick
      : defAction
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      isLeftOrientation ? null : mkLabel(label, size, textParams, isActive)
      checkBox(isChecked.value, isActive, sf & S_HOVER)
      !isLeftOrientation ? null : mkLabel(label, size, textParams, isActive, !isLeftOrientation)
    ]
  }.__update(blockParams))
}


return mkCheckbox