from "%enlSqGlob/ui_library.nut" import *

let textButton = require("%ui/components/textButton.nut")

return @(opt, _group, xmbNode){
  size = [flex(), SIZE_TO_CONTENT]
  children = @() {
    watch = opt.var
    stopHover = true
    children = textButton(opt.var.value?.text, @() opt.var.value?.handler(), {
      xmbNode
      stopHover = true
    })
  }
}