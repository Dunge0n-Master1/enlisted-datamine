from "%enlSqGlob/ui_library.nut" import *

let httpRequest = require("httpRequest.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { get_circuit_conf } = require("app")

let purchased = Watched({})

let { checkPurchasesUrl = "https://purch.gaijinent.com/check_purchase.php" } = get_circuit_conf()

let refresh = function() {
  if (!purchased.value.len() || !userInfo.value)
    return

  httpRequest.requestData(checkPurchasesUrl,
    httpRequest.createGuidsRequestParams(purchased.value.keys()),
    function(data) {
      let purchasedUpdate = {}
      foreach (guid, amount in data?.items ?? {})
        purchasedUpdate[guid] <- amount
      if (null != purchasedUpdate.findvalue(@(amount, guid) purchased.value?[guid] != amount))
        purchased.mutate(@(v) v.__update(purchasedUpdate))
    })
}

let function addGuids(guids) {
  let wasTotal = purchased.value.len()
  foreach (guid in guids)
    if (!(guid in purchased.value))
      purchased.value[guid] <- 0
  if (wasTotal != purchased.value.len())
    refresh()
}

userInfo.subscribe(function(val) {
  if (val)
    refresh()
  else
    purchased.value.clear()
})

return {
  purchased = purchased
  addGuids = addGuids
  refreshPurchased = refresh
}