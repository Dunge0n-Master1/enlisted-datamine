from "%enlSqGlob/ui_library.nut" import *

let { getPreferredVersion } = require("sony.webapi")
if (getPreferredVersion() == 2)
  return require("%enlist/ps4/sessionManager.nut")
return require("%enlist/ps4/sessionInvitation.nut")
