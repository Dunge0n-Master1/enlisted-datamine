from "%enlSqGlob/ui_library.nut" import *

let { eulaVersion, showEula } = require("%enlist/eula/eula.nut")
let platform = require("%dngscripts/platform.nut")

let onlineSettings = require("%enlist/options/onlineSettings.nut")
let eulaEnabled = (platform.is_xbox || platform.is_sony)
let function action(_login_status, cb) {
  if (!eulaEnabled) {
    log("eula check disabled")
    cb({})
    return
  }

  log($"eulaVersion {eulaVersion}")
  if (onlineSettings.settings.value?["acceptedEULA"] != eulaVersion) {
    showEula(function(accept) {
      log("showEula")
      if (accept) {
        onlineSettings.settings.mutate(@(value) value["acceptedEULA"] <- eulaVersion)
        cb({})
      }
      else
        cb({stop = true})
    })
  }
  else {
    cb({})
  }
}

return {
  id  = "eula"
  action = action
}