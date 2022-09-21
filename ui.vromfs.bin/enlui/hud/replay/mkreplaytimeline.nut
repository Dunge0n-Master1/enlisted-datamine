from "%enlSqGlob/ui_library.nut" import *

let { tabBgColor, colPart, titleTxtColor, defBdColor, commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")
let { buttonSound } = require("%ui/style/sounds.nut")
let { sound_play } = require("sound")

let calcFrameColor = @(sf) (sf & S_HOVER) ? tabBgColor : titleTxtColor
let calcKnobColor =  @(sf) (sf & S_ACTIVE) ? tabBgColor : titleTxtColor
let knobSize = [colPart(0.35), colPart(0.35)]

let function mkTimeLine(var, options={}) {
  let minval = options?.min ?? 0
  let maxval = options?.max ?? 1
  let group = ElemGroup()

  let knob = watchElemState(@(sf) {
    size = knobSize
    group
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [[ VECTOR_ELLIPSE, 0, 50, 50, 50 ]]
    fillColor = calcKnobColor(sf)
    color = sf & S_ACTIVE ? titleTxtColor : defBdColor
  })


  let setValue = options?.setValue ?? @(v) var(v)
  let function onChange(factor){
    let value = factor.tofloat() * (maxval - minval) + minval
    let oldValue = var.value
    if (!(options?.canChangeVal ?? true))
      return
    setValue(value)
    if (oldValue != var.value)
      sound_play("ui/slider")
  }

  return watchElemState(function(sf) {
    let factor = clamp((var.value.tofloat() - minval) / (maxval - minval), 0, 1)
    return {
      watch = var
      size = [flex(), colPart(0.20)]
      sound = buttonSound
      behavior = Behaviors.Slider
      min = 0
      max = 1
      group
      fValue = factor
      onChange
      valign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          size = flex()
          children = [
            {
              group
              rendObj = ROBJ_BOX
              size = [flex(factor), flex()]
              fillColor =  calcFrameColor(sf)
              borderWidth = sf & S_HOVER ? hdpx(1) : hdpx(0)
              borderRadius = factor < 1.0
                ? [commonBorderRadius, 0, 0, commonBorderRadius]
                : commonBorderRadius
              borderColor = tabBgColor
            }
            {
              group
              rendObj = ROBJ_BOX
              fillColor = defBdColor
              borderRadius = factor > 0.0
                ? [0, commonBorderRadius, commonBorderRadius, 0]
                : commonBorderRadius
              size = [flex(1.0 - factor), flex()]
            }
          ]
        }
        sf & S_HOVER
          ? {
              pos = [pw(factor * 100), 0]
              children = knob
            }
          : null
      ]
    }
  })
}


return mkTimeLine