from "%enlSqGlob/ui_library.nut" import *

let { savedCrossnetworkPlayId, savedCrossnetworkStateUpdate } = require("%enlSqGlob/crossnetwork_state.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")

return function(val) {
  settings.mutate(@(v) v[savedCrossnetworkPlayId] <- val)
  savedCrossnetworkStateUpdate(val)
}
