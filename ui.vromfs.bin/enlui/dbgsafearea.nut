from "%enlSqGlob/ui_library.nut" import *

let {safeAreaShow, safeAreaAmount} = require("%enlSqGlob/safeArea.nut")

let function dbgSafeArea(){
  return {
    size = [sw(100*safeAreaAmount.value), sh(100*safeAreaAmount.value)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = safeAreaShow.value ? ROBJ_FRAME : null
    watch = [safeAreaShow, safeAreaAmount]
    borderWidth = hdpx(1)
    color = Color(255,128,128)
  }
}

return { dbgSafeArea }