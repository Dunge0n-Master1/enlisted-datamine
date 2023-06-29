from "%enlSqGlob/ui_library.nut" import *

let { defItemBlur, darkTxtColor, defTxtColor } = require("%enlSqGlob/ui/designConst.nut")


let lockColor = 0xFFFFFFFF
let lockIconSize = hdpxi(20)
let lockObjSize = hdpx(32)

let mkLockedBlock = @(color) {
  rendObj = ROBJ_WORLD_BLUR
  size = flex()
  fillColor = color
  color = defItemBlur
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      size = flex()
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth = hdpx(2)
      color = lockColor
      opacity = 0.05
      commands = [[ VECTOR_LINE, 0, 0, 100, 100 ], [ VECTOR_LINE, 0, 100, 100, 0 ]]
    }
    {
      size = [lockObjSize, lockObjSize]
      rendObj = ROBJ_VECTOR_CANVAS
      commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
      fillColor = color
      color
    }
    {
      rendObj = ROBJ_IMAGE
      size = array(2, lockIconSize)
      image = Picture($"ui/skin#locked_icon.svg:{lockIconSize}:{lockIconSize}:K")
      color = lockColor
      opacity = 0.05
    }
  ]
}


let mkEmptyItemSlotImg = function(img, imgSize, group, isSelected) {
  if (img == null)
    return null
  let image = Picture($"ui/skin#{img}:{imgSize}:{imgSize}:K")
  return watchElemState(@(sf) {
    watch = isSelected
    size = array(2, imgSize)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    group
    color = (sf & S_HOVER) || isSelected.value ? darkTxtColor : defTxtColor
    image
    opacity = (sf & S_HOVER) || isSelected.value ? 1 : 0.2
  })
}


return {
  mkLockedBlock
  mkEmptyItemSlotImg
}
