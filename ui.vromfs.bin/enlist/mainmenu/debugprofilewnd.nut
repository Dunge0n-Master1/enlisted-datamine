from "%enlSqGlob/ui_library.nut" import *

let { openDebugWnd } = require("%enlist/components/debugWnd.nut")
let profile = require("%enlist/meta/servProfile.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let combined = profile.__merge({ userInfo })
let tabs = combined.keys()
  .sort(@(a, b) a <=> b)
  .map(@(n) { id = n, data = combined[n], maxItems = 100 })

return @() openDebugWnd({
  wndUid = "debug_profile_wnd"
  tabs = tabs
})
