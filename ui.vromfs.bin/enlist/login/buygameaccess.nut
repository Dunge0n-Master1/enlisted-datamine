from "%enlSqGlob/ui_library.nut" import *

let { is_pc } = require("%dngscripts/platform.nut")

local buyAccess = null
if (is_pc) {
  let openUrl = require("%ui/components/openUrl.nut")
  buyAccess = @() openUrl("https://enlisted.net/#!/cbt/shop")
}
else
  buyAccess = require("%enlist/consoleStore/consoleStore.nut").openBundles

return buyAccess