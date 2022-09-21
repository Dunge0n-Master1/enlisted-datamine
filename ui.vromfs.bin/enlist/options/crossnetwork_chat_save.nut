from "%enlSqGlob/ui_library.nut" import *

let { is_xbox } = require("%dngscripts/platform.nut")
let {
  xboxCrosschatAvailable, savedCrossnetworkChatId, savedCrossnetworkChatStateUpdate
} = require("%enlSqGlob/crossnetwork_state.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")

let {
  check_privilege = @(...) null,
  Communications = -1
} = is_xbox ? require_optional("xbox.user") : null


return function(val, setValueFunc) {
  // Need notify member on trying to change restriction
  // if it is restricted in system menu
  if (is_xbox && !xboxCrosschatAvailable.value) {
    check_privilege(Communications, true, "")
    return
  }

  settings.mutate(@(v) v[savedCrossnetworkChatId] <- val)
  savedCrossnetworkChatStateUpdate(val)
  setValueFunc(val)
}