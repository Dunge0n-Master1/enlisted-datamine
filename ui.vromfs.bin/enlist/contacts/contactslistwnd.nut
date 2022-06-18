from "%enlSqGlob/ui_library.nut" import *

let { is_nswitch } = require("%dngscripts/platform.nut")

let show = is_nswitch
  ? require("contactsListWndNswitch.nut")
  : require("contactsListWndCommon.nut")

return {
  show
}
