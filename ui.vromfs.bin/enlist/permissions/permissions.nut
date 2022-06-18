from "%enlSqGlob/ui_library.nut" import *

let platform = require("%dngscripts/platform.nut")
let {isProductionCircuit} = require("%dngscripts/appInfo.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { subscribe } = require("eventbus")

let dbgMultiplayerPermissions = Watched(true)
local checkMultiplayerPermissions = function checkMultiplayerPermissionsImpl() { //<--- overriden in ps5 version
  if (dbgMultiplayerPermissions.value)
    return true
  else
    msgbox.show({text = loc("No multiplayer permissions")})
}
console_register_command(function() {
  dbgMultiplayerPermissions(!dbgMultiplayerPermissions.value)
  console_print($"mutliplayer permissions set to: {dbgMultiplayerPermissions.value}")
}, "feature.toggleMultiplayerPermissions")

if (platform.is_ps5) {
  let { hasPremium, requestPremiumStatusUpdate } = require("sony.user")
  subscribe("psPlusSuggested", @(_) requestPremiumStatusUpdate(@(_) null))
  let { suggest_psplus } = require("sony.store")

  let function suggestAndAllowPsnPremiumFeatures() {
    if (hasPremium() || isProductionCircuit.value) //do not check multiplayer permission in production
      return true

    suggest_psplus("psPlusSuggested", {})
    return false
  }

  checkMultiplayerPermissions = suggestAndAllowPsnPremiumFeatures
}

return {
  checkMultiplayerPermissions
}