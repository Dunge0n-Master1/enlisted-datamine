from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let currenciesList = mkWatched(persist, "currenciesList", [])
let matchingNotifications = require("%enlSqGlob/notifications/matchingNotifications.nut")

let balance = mkWatched(persist, "currencyBalance", {})
let expiring = mkWatched(persist, "expiring", {})
let purchases = mkWatched(persist, "purchases", {})

userInfo.subscribe(function(v) {
  if (v)
    return
  balance({})
  purchases({})
})

let function mkCurrency(config){
  let id = config.id
  return {
    id = id
    image = @(_size) null
    locId = $"currency/code/{id}"
  }.__update(config)
}
let sorted = Computed(function(){
  return currenciesList.value.map(mkCurrency)
})
let byId = Computed(function(){
  let res = {}
  foreach (config in currenciesList.value){
    let currency = mkCurrency(config)
    let id = currency.id
    assert(!(id in res), $"Currency: duplicate currency id {id}")
    res[id] <- currency
  }
  return res
})

let notifications = {
  update_balance = function(ev) {
    if (typeof(ev?.balance) != "table") {
      log("Got currency notification without balance table")
      return
    }
    let newBalance = clone balance.value
    let newExpiring = clone expiring.value
    foreach (k, v in ev.balance) {
      newBalance[k] <- v?.value
      newExpiring[k] <- v?.expiring
    }
    if (!isEqual(newBalance, balance.value))
      balance(newBalance)
    if (!isEqual(newExpiring, expiring.value))
      expiring(newExpiring)
  }

  function update_purchasable_list(ev) {
    let newPurch = ev?.purchases ?? {}
    if (!isEqual(newPurch, purchases.value))
      purchases(newPurch)
  }
}

let function processNotification(ev) {
  let handler = notifications?[ev?.func]
  if (handler)
    handler(ev)
  else
    log("Unexpected currency notification type:", (ev?.func ?? "null"))
}

matchingNotifications.subscribe("currency", processNotification)


console_register_command(@() console_print(balance.value), "currencies.balance")
console_register_command(@(key, val) balance.mutate(@(data) data[key] <- val), "currencies.set")

let showRealCurrencyPrices = mkWatched(persist, "showRealCurrencyPrices", true)

return {
  byId = byId
  sorted = sorted
  balance = balance
  expiring = expiring
  purchases = purchases
  currenciesList = currenciesList
  processNotification = processNotification
  showRealCurrencyPrices = showRealCurrencyPrices
}
