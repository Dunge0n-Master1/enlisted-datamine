from "%enlSqGlob/ui_library.nut" import *

return kwarg(@(iconColor = Color(255, 255, 255), iconSize = hdpx(36)) {
  size = [iconSize.tointeger(), iconSize.tointeger()]
  rendObj = ROBJ_IMAGE
  color = iconColor
  image = Picture($"!ui/uiskin/crossplay.svg:{iconSize.tointeger()}:{iconSize.tointeger()}:K")
  keepAspect = KEEP_ASPECT_FIT
})