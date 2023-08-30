from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let matchingNotifications = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")

let currenciesList = mkWatched(persist, "currenciesList", [])

let currenciesBalance = nestWatched("currenciesBalance", {})
let currenciesExpiring = nestWatched("currenciesExpiring", {})
let currenciesPurchases = nestWatched("currenciesPurchases", {})

userInfo.subscribe(function(v) {
  if (v)
    return
  currenciesBalance({})
  currenciesPurchases({})
})

let function mkCurrency(config){
  let id = config.id
  return {
    id = id
    image = @(_size) null
    locId = $"currency/code/{id}"
  }.__update(config)
}

let currenciesSorted = Computed(@() currenciesList.value.map(mkCurrency))

let currenciesById = Computed(function(){
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
    let newBalance = clone currenciesBalance.value
    let newExpiring = clone currenciesExpiring.value
    foreach (k, v in ev.balance) {
      newBalance[k] <- v?.value
      newExpiring[k] <- v?.expiring
    }
    if (!isEqual(newBalance, currenciesBalance.value))
      currenciesBalance(newBalance)
    if (!isEqual(newExpiring, currenciesExpiring.value))
      currenciesExpiring(newExpiring)
  }

  update_purchasable_list = function(ev) {
    let newPurch = ev?.purchases ?? {}
    if (!isEqual(newPurch, currenciesPurchases.value))
      currenciesPurchases(newPurch)
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


console_register_command(@() console_print(currenciesBalance.value), "currencies.balance")
console_register_command(function(key, val) {
  let balance = clone currenciesBalance.value
  balance[key] <- val
  currenciesBalance(balance)
}, "currencies.set")

let hasValidBalance = Computed(@() currenciesBalance.value.findindex(@(val) val < 0) == null)

return {
  currenciesById
  currenciesSorted

  currenciesBalance
  currenciesExpiring
  hasValidBalance

  currenciesList
}
