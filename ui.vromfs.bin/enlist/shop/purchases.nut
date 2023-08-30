from "%enlSqGlob/ui_library.nut" import *

let httpRequest = require("httpRequest.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { get_circuit_conf } = require("app")

let purchased = Watched({})

let { checkPurchasesUrl = "https://purch.gaijinent.com/check_purchase.php" } = get_circuit_conf()

let function refreshPurchased() {
  if (purchased.value.len() == 0 || !userInfo.value)
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
  let update = {}
  foreach (guid in guids)
    if (guid not in purchased.value)
      update[guid] <- 0
  if (update.len() > 0) {
    purchased.mutate(@(v) v.__update(update))
    refreshPurchased()
  }
}

userInfo.subscribe(function(val) {
  if (val)
    refreshPurchased()
  else
    purchased({})
})

return {
  purchased
  addGuids
  refreshPurchased
}