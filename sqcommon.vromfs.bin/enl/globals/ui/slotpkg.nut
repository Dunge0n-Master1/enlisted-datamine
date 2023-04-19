from "%enlSqGlob/ui_library.nut" import *

let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { defItemBlur, defSlotBgColor, hoverSlotBgColor, enableItemIdleBgColor, defLockedSlotBgColor,
  defTxtColor, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")

enum SlotStatuses {
  GENERAL
  ENABLE
  LOCKED
  DEBUG
}

let debugItemBgColor       = 0x99282939


let mkSlotBgOverride = @(isActive = false, status = SlotStatuses.GENERAL) {
  rendObj = isActive ? ROBJ_SOLID : ROBJ_WORLD_BLUR
  fillColor = status == SlotStatuses.DEBUG ? debugItemBgColor
    : status == SlotStatuses.ENABLE ? enableItemIdleBgColor
    : status == SlotStatuses.LOCKED ? defLockedSlotBgColor
    : defSlotBgColor
  color = isActive ? hoverSlotBgColor : defItemBlur
}

let mkSlotTextOverride = @(isActive) {
  rendObj = ROBJ_TEXT
  color = isActive ? darkTxtColor : defTxtColor
}

let mkSlotTextareaOverride = @(isActive) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = isActive ? 0xFF333333 : 0xFFC4C4C4
}


let levelCommonNestImg = mkColoredGradientX(0x33FFFFFF, 0x00FFFFFF, 10, false)
let levelInvertNestImg = mkColoredGradientX(0x33000000, 0x00000000, 10, false)


let mkLevelNest = @(isActive, children) {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_IMAGE
  image = isActive ? levelInvertNestImg : levelCommonNestImg
  children
}


return {
  mkSlotBgOverride
  mkSlotTextOverride
  SlotStatuses
  mkSlotTextareaOverride
  mkLevelNest
  debugItemBgColor
}
