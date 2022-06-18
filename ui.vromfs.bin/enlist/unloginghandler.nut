from "%enlSqGlob/ui_library.nut" import *

let loginState     = require("%enlSqGlob/login_state.nut")
let char           = require("%enlSqGlob/charClient.nut")?.low_level_client
let userstat       = require_optional("userstats")
let inventory      = require_optional("inventory")


loginState.isLoggedIn.subscribe(function(logged) {
  if (logged)
    return

  // TODO: Better to do it in C++.
  char?.clearCallbacks()
  char?.clearEvents()

  inventory?.clearCallbacks()
  inventory?.clearEvents()

  userstat?.clearCallbacks()
  userstat?.clearEvents()
})