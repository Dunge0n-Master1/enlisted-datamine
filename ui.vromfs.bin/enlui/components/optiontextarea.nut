from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")

return function(opt, group, _xmbNode){
  return {
    size = [flex(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children =  @() {
      text = opt.var.value?.text
      size = [flex(), SIZE_TO_CONTENT]
      watch = opt.var
      rendObj = ROBJ_TEXTAREA
      group
      behavior = Behaviors.TextArea
      color = Color(160,160,160)
      //maxContentWidth = pw(100)
    }.__merge(sub_txt, type(opt.var?.value)=="table" ? opt.var.value : {})
  }
}