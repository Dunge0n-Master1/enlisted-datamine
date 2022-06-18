from "%enlSqGlob/ui_library.nut" import *

let extAutoRefreshTimer = require("%enlist/state/extAutoRefreshTimer.nut")
let { check_purchases } = require("%enlist/meta/clientApi.nut")

let AUTO_REFRESH_DELAY = 30.0 //sec between several window inactivates without mve to shop link
let CHECK_PURCHASED_PERIOD = 10.0 //sec to check purchases after return back to game after shop link
let MAX_PURCHASES_CHECK = 6 //amount of purchases check after back from shopLink

let { refreshOnWindowActivate } = extAutoRefreshTimer({
  refresh = check_purchases
  refreshDelaySec = AUTO_REFRESH_DELAY
})

let itemsRefresh =
  @() refreshOnWindowActivate(MAX_PURCHASES_CHECK, CHECK_PURCHASED_PERIOD)

return itemsRefresh