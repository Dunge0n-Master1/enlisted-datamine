from "%enlSqGlob/ui_library.nut" import *

let flaskIcon = memoize(@(size)
  Picture("ui/skin#flask_icon.svg:{0}:{0}:K".subst(size)))

let mkFlaskIcon = memoize(@(size, color) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  color
  image = flaskIcon(size)
})

return mkFlaskIcon