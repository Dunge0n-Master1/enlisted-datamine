from "%enlSqGlob/ui_library.nut" import *


let lockColor = 0xFFFFFFFF

let mkLockedBlock = @(color) {
  size = flex()
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
      size = [36, 36]
      rendObj = ROBJ_VECTOR_CANVAS
      commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
      fillColor = color
      color
    }
    {
      rendObj = ROBJ_IMAGE
      size = array(2, 20)
      image = Picture($"ui/skin#locked_icon.svg:{20}:{20}:K")
      color = lockColor
      opacity = 0.05
    }
  ]
}


let mkEmptyItemSlotImg = @(img, imgSize) img == null ? null
  : {
      size = array(2, imgSize)
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/skin#{img}:{imgSize}:{imgSize}:K")
      opacity = 0.2
    }


return {
  mkLockedBlock
  mkEmptyItemSlotImg
}
