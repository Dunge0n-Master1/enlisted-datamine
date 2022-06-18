from "%enlSqGlob/ui_library.nut" import *

return @(content, size = SIZE_TO_CONTENT) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = Color(30, 30, 30, 160)
  size
  children = {
    rendObj = ROBJ_FRAME
    size
    color =  Color(50, 50, 50, 20)
    borderWidth = hdpx(1)
    padding = fsh(1)
    children = content
  }
}