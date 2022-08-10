from "%enlSqGlob/ui_library.nut" import *

let medkitIcon = memoize(@(size)
  Picture("ui/skin#healing_icon.svg:{0}:{1}:K".subst(size[0], size[1])))

let mkMedkitIcon = memoize(@(size) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = medkitIcon([size, size])
})

return {
  medkitIcon
  mkMedkitIcon
}