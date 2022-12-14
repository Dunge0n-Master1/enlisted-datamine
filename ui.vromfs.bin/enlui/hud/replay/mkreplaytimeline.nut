from "%enlSqGlob/ui_library.nut" import *

let { accentColor, colPart, titleTxtColor, defBdColor, commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")


let function mkTimeLine(var, options={}) {
  let minval = options?.min ?? 0
  let maxval = options?.max ?? 1
  let group = ElemGroup()


  let setValue = options?.setValue ?? @(v) var(v)
  let function onChange(factor){
    let value = factor.tofloat() * (maxval - minval) + minval
    if (!(options?.canChangeVal ?? true))
      return
    setValue(value)
  }

  return function() {
    let factor = clamp((var.value.tofloat() - minval) / (maxval - minval), 0, 1)
    return {
      watch = var
      size = [flex(), colPart(0.20)]
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
              fillColor = titleTxtColor
              borderRadius = factor < 1.0
                ? [commonBorderRadius, 0, 0, commonBorderRadius]
                : commonBorderRadius
              borderColor = accentColor
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
      ]
    }
  }
}


return mkTimeLine