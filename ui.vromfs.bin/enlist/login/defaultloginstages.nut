from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let { disableNetwork, usePCLogin } = require("%enlSqGlob/login_state.nut")

return disableNetwork || usePCLogin ? require("chains/login_pc.nut")
  : platform.is_xbox ? require("chains/login_xbox.nut")
  : platform.is_sony ? require("chains/login_ps4.nut")
  : platform.is_nswitch ? require("chains/login_nswitch.nut")
  : platform.is_android ? require("chains/login_android.nut")
  : require("chains/login_pc.nut")
