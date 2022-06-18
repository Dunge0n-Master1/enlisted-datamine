from "%enlSqGlob/ui_library.nut" import *

let {breath_shortness, breath_low_anim_trigger, breath_low_threshold} = require("%ui/hud/state/breath_state.nut")
let {barHeight, barWidth} = require("style.nut")

let breathAnim = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, easing=CosineFull, trigger=breath_low_anim_trigger, loop=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic }
]


let breathBgColor = Color(30, 30, 50, 40)
let breathFgColor = Color(80, 180, 250, 205)
let breathWarnColor = Color(255, 30, 300, 255)

let function breath() {
  local ratio = 0
  local children = null
  if (breath_shortness.value != null && breath_shortness.value < 1.0) {
    ratio = breath_shortness.value

    let breathWarning = breath_shortness.value < breath_low_threshold ? {
      rendObj = ROBJ_SOLID
      color = breathWarnColor
      size = [barWidth * ratio,flex()]
      animations = breathAnim
    } : null

    children = [
      {
        rendObj = ROBJ_SOLID
        size = [barWidth, barHeight]
        color = breathBgColor
        halign = ALIGN_RIGHT
        children = [
          {
            rendObj = ROBJ_SOLID
            color = breathFgColor
            size = [barWidth*ratio,flex()]
          }
         breathWarning
        ]
      }
    ]
  }


  return {
    size = [barWidth, barHeight]
    watch = breath_shortness
    children = children
  }
}

return breath