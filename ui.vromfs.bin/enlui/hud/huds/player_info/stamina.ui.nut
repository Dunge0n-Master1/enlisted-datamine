from "%enlSqGlob/ui_library.nut" import *

let {stamina, staminaAnimTrigger, scaleStamina} = require("%ui/hud/state/stamina_es.nut")
let {flaskAffectApplied} = require("%ui/hud/state/flask.nut")
let {barHeight, barWidth} = require("style.nut")

let staminaAnim = [
  { prop=AnimProp.fgColor, from=Color(255,255,250), to=Color(220,225,100), easing=CosineFull,
    duration=0.5, trigger=staminaAnimTrigger, loop=true
  }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic }
]


let showStamina = Computed(@() stamina.value != null
  && stamina.value >= 0
  && (stamina.value < 100 || flaskAffectApplied.value))

let function staminaComp() {
  local ratio = 0
  local children = null

  local width = barWidth
  if (showStamina.value) {
    ratio = clamp(stamina.value, 0.0, 100.0) / 100.0
    let ir = 1.0-ratio
    let colorBg = Color(30, 30, 50, 40)
    let colorFg = flaskAffectApplied.value
      ? Color(30+ir*170, 135+ir*120, 255-ir*150, 255)
      : Color(70+ir*170, 80+ir*170, 255-ir*150, 255)
    width *= scaleStamina.value

    children = [
      {
        rendObj = ROBJ_SOLID
        size = [width, barHeight]
        color = colorBg
        halign = ALIGN_RIGHT
        children = {
          rendObj = ROBJ_SOLID
          color = colorFg
          size = [width*ratio,flex()]
        }
        animations = staminaAnim
      }
    ]
  }


  return {
    size = [width, barHeight]
    watch = [stamina, showStamina, flaskAffectApplied]
    children = children
  }
}

return staminaComp