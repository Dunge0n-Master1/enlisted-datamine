from "%enlSqGlob/ui_library.nut" import *

let medkitIcon = memoize(@(size)
  Picture("ui/skin#healing_icon.svg:{0}:{0}:K".subst(size)))

let mkMedkitIcon = memoize(@(size, color) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  color
  image = medkitIcon(size)
})

return mkMedkitIcon