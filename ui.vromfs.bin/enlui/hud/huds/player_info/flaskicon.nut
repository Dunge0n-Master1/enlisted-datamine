from "%enlSqGlob/ui_library.nut" import *

let flaskIcon = @(size)
  Picture("ui/skin#flask_icon.svg:{0}:{1}:K".subst(size[0], size[1]))

let mkFlaskIcon = @(size) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = flaskIcon([size, size])
}

return {
  flaskIcon
  mkFlaskIcon
}