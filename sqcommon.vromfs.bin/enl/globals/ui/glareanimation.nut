from "%enlSqGlob/ui_library.nut" import *

let { airHoverBgColor } = require("%enlSqGlob/ui/viewConst.nut")

let animChild = @(size, color, animations = []){
  rendObj = ROBJ_SOLID
  size
  color
  pos = [0, -size[1]/2]
  opacity = 0.5
  animations
  transform = {
    rotate = 45.0
  }
}

let animChildren = @(animations){
  flow = FLOW_HORIZONTAL
  pos = [-hdpx(80), 0]
  vplace = ALIGN_TOP
  gap = hdpx(40)
  children = [
    animChild([hdpx(8), hdpx(200)], airHoverBgColor, animations)
    animChild([hdpx(30), hdpx(200)], airHoverBgColor, animations)
  ]
}

let glareAnimation = @(delay = 0)[
  { prop = AnimProp.translate, from = [-hdpx(1000), 0], to = [hdpx(1000), 0],
    duration = 4, play = true, loop = true, delay }
]

return {
  animChildren
  glareAnimation
}