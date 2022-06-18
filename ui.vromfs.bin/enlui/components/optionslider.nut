from "%enlSqGlob/ui_library.nut" import *

let slider = require("slider.nut")

let function optionSlider(opt, group, xmbNode) {
  let sliderElem = {
    size = flex()

    children = slider.Horiz(opt.var, {
      min = opt?.min ?? 0
      max = opt?.max ?? 1
      unit = opt?.unit ?? 0.1
      scaling = opt?.scaling
      pageScroll = opt?.pageScroll ?? 0.1
      group
      xmbNode
      setValue = opt?.setValue
    })
  }

  return sliderElem
}

let export = class {
  _call = @(_self, opt, group, xmbNode) optionSlider(opt, group, xmbNode)
  scales = slider.scales
}()

return export
