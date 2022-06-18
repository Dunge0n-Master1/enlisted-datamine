from "%enlSqGlob/ui_library.nut" import *

let {inTank, inPlane} = require("%ui/hud/state/vehicle_state.nut")
let isAnyMenuVisible = require("isAnyMenuVisible.nut")

return {
  isVisible = Computed(@() (inTank.value || inPlane.value) && !isAnyMenuVisible.value)
}