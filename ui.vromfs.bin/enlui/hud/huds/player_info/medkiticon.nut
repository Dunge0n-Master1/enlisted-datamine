from "%enlSqGlob/ui_library.nut" import *

let medkitIcon = @(size)
  Picture("ui/skin#healing_icon.svg:{0}:{1}:K".subst(size[0], size[1]))

let mkMedkitIcon = @(size) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = medkitIcon([size, size])
}

return {
  medkitIcon
  mkMedkitIcon
}