from "%enlSqGlob/ui_library.nut" import *

let { commonBtnHeight, disabledTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let {
  glareAnimation, animChildren
} = require("%enlSqGlob/ui/glareAnimation.nut")

let BgHover = Color(220, 220, 220)

// btn styles to use in computed styles
let purchaseButtonStyle = {
  style = {
    BgActive = Color(178,35,9)
    BgHover
  }
  overrideBySf = @(sf, _) sf & S_HOVER
    ? {
        rendObj = ROBJ_BOX
        borderWidth = hdpx(1)
      }
    : {
        rendObj = ROBJ_IMAGE
        image = Picture("!ui/gameImage/purchase_btn_bg.svg:200:20:K?Ac")
      }
}

let primaryBtnAnimation = [
  { prop = AnimProp.fillColor, from = Color(1,79,181), to = 0xfa0182b5
    easing = CosineFull, duration = 1.5, loop = true, play = true }
]

let primaryFlatButtonStyle = {
  size = [SIZE_TO_CONTENT, commonBtnHeight],
  style = {
    BgActive = Color(1,79,181)
    BgHover
    BgDisabled = Color(1,30,100)
    TextDisabled = disabledTxtColor
  }
  overrideBySf = @(sf, isEnabled) (sf & S_HOVER) || (sf & S_ACTIVE) || !isEnabled
    ? null
    : {
        bgChild = {
          key = "bgChild"
          rendObj = ROBJ_BOX
          borderWidth = 0
          color = 0xfa0182b5
          size = flex()
          animations = primaryBtnAnimation
        }
        fgChild = animChildren(glareAnimation())
      }
}

return {
  purchaseButtonStyle
  primaryFlatButtonStyle
}