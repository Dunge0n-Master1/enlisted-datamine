from "%enlSqGlob/ui_library.nut" import *

let spinnerList = require("spinnerList.nut")

let locOn = loc($"option/on")
let locOff = loc($"option/off")
let function optionCheckbox(opt, group, xmbNode) {
  let available = Watched([false, true])
  let stateFlags = Watched(0)
  return @(){
    size = flex()
    watch = available
    children = spinnerList({
      isEqual = opt?.isEqual
      setValue = opt?.setValue
      curValue = opt.var
      valToString = opt?.valToString ?? @(val) val ? locOn : locOff
      allValues = available.value
      xmbNode
      group
      stateFlags
    })
  }
}

return optionCheckbox
