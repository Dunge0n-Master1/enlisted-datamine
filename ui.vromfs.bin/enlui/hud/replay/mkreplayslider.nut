from "%enlSqGlob/ui_library.nut" import *

let { accentColor, colPart, titleTxtColor, defBdColor, hoverTxtColor, defTxtColor,
  smallPadding, disabledTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")

let calcFrameColor = @(sf) sf & S_HOVER ? accentColor : titleTxtColor
let calcKnobColor =  @(sf, isEnabled) !isEnabled ? disabledTxtColor
  : sf & S_ACTIVE ? accentColor
  : titleTxtColor

let defLabelStyle = {
  color = defTxtColor
}.__update(fontSmall)

let hoverLabelStyle = {
  color = hoverTxtColor
}.__update(fontSmall)

let knobSize = [colPart(0.22), colPart(0.22)]


let function mkSlider(var, label, options = {}) {
  let minval = options?.min ?? 0
  let maxval = options?.max ?? 1
  let setValue = options?.setValue ?? @(v) var(v)
  let rangeval = maxval - minval
  let step = options?.step
  let unit = options?.unit ?? step ? step / rangeval : 0.01
  let isEnabled = options?.isEnabled ?? true
  let group = ElemGroup()

  let knob = watchElemState(@(sf) {
    size = knobSize
    group
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [[ VECTOR_ELLIPSE, 0, 50, 50, 50 ]]
    fillColor = calcKnobColor(sf, isEnabled)
    color = sf & S_ACTIVE ? titleTxtColor : defBdColor
  })

  let sliderText = @(text, sf) {
    rendObj = ROBJ_TEXT
    group
    text
  }.__update(sf & S_HOVER ? hoverLabelStyle : defLabelStyle)


  let function onChange(factor){
    let value = factor.tofloat() * (maxval - minval) + minval
    if (!isEnabled)
      return
    setValue(value)
  }

  return watchElemState(function(sf) {
    let factor = clamp((var.value.tofloat() - minval) / (maxval - minval), 0, 1)
    let valueToShow = options?.valueToShow ?? var.value
    return {
      watch = var
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.Slider
      min = 0
      max = 1
      unit
      ignoreWheel = true
      group
      fValue = factor
      onChange
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            sliderText(label, sf)
            sliderText(valueToShow, sf).__update({ hplace = ALIGN_RIGHT })
          ]
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          children = [
            {
              flow = FLOW_HORIZONTAL
              size = [flex(), colPart(0.1)]

              children = [
                {
                  group
                  rendObj = ROBJ_BOX
                  size = [flex(factor), flex()]
                  fillColor =  calcFrameColor(sf)
                  borderWidth = sf & S_HOVER ? hdpx(1) : hdpx(0)
                  borderRadius = factor < 100.0 ? [hdpx(2), 0, 0, hdpx(2)] : hdpx(2)
                  borderColor = accentColor
                }
                {
                  group
                  rendObj = ROBJ_BOX
                  fillColor = defBdColor
                  borderRadius = factor > 0.0 ? [0, hdpx(2), hdpx(2), 0] : hdpx(2)
                  size = [flex(1.0 - factor), flex()]
                }
              ]
            }
            {
              pos = [pw(factor * 100), 0]
              children = knob
            }
          ]
        }
      ]
    }
  })
}


return mkSlider