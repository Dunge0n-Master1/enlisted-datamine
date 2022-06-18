from "%enlSqGlob/ui_library.nut" import *

let {safeAreaAmount} = require("%enlSqGlob/safeArea.nut")

let defBorders = [0, fsh(4), fsh(4), fsh(4)]
let safeAreaBorders = Computed(
  function(){
    let verScreenPadding = sh(100*(1-safeAreaAmount.value)/2)
    let horScreenPadding = sw(100*(1-safeAreaAmount.value)/2)
    return [max(verScreenPadding, defBorders[0]), max(horScreenPadding, defBorders[1]), max(verScreenPadding, defBorders[2]), max(horScreenPadding, defBorders[3])]
  }
)

return {
  safeAreaBorders,
  safeAreaSize = Computed(@() [sw(100) - safeAreaBorders.value[1] - safeAreaBorders.value[3], sh(100) - safeAreaBorders.value[0] - safeAreaBorders.value[2]])
  safeAreaAmount,
  isWideScreen = sw(100).tofloat() / sh(100) > 1.5
}