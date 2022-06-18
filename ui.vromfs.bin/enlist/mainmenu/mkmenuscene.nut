from "%enlSqGlob/ui_library.nut" import *

let { lerp } = require("%sqstd/math.nut")
let { navHeight } = require("mainmenu.style.nut")
let { gap } = require("%enlSqGlob/ui/viewConst.nut")
let { safeAreaAmount, safeAreaBorders } = require("%enlist/options/safeAreaState.nut")


let menuContentAnimation = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
]

let lerp_top_margin = @(v) lerp(0.9, 1.0, 0.3, 1, v)
let lerp_bottom_margin = @(v) lerp(0.9, 1.0, 1.15, 1, v)
let mkMenuScene = @(headerBar, content, bottomBar) function() {
  let borders = safeAreaBorders.value
  let saAmount = safeAreaAmount.value
  return {
    watch = [safeAreaBorders, safeAreaAmount]
    size = [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    behavior = Behaviors.MenuCameraControl
    children = [
      {
        size = [flex(), navHeight]
        margin = [borders[0], 0, fsh(2) * lerp_top_margin(safeAreaAmount.value), 0]
        padding = [0, max(borders[1], fsh(1)), 0, max(borders[3], fsh(0.5))]
        children = headerBar
      }
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [0, borders[1], borders[2]*lerp_bottom_margin(saAmount), borders[3]]
        gap = gap
        children = [
          content
          bottomBar
        ]
      }
    ]
  }
}

return {
  mkMenuScene
  menuContentAnimation
}