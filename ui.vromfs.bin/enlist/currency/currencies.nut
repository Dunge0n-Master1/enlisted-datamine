from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let matchingNotifications = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { globalWatched } = require("%dngscripts/globalState.nut")

let currenciesList = mkWatched(persist, "currenciesList", [])

let { currenciesBalance, currenciesBalanceUpdate } = globalWatched("currenciesBalance", @() {})
let { currenciesExpiring, currenciesExpiringUpdate } = globalWatched("currenciesExpiring", @() {})
let { currenciesPurchases, currenciesPurchasesUpdate } = globalWatched("currenciesPurchases", @() {})

userInfo.subscribe(function(v) {
  if (v)
    return
  currenciesBalanceUpdate({})
  currenciesPurchasesUpdate({})
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
      currenciesBalanceUpdate(newBalance)
    if (!isEqual(newExpiring, currenciesExpiring.value))
      currenciesExpiringUpdate(newExpiring)
  }

  update_purchasable_list = function(ev) {
    let newPurch = ev?.purchases ?? {}
    if (!isEqual(newPurch, currenciesPurchases.value))
      currenciesPurchasesUpdate(newPurch)
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
  currenciesBalanceUpdate(balance)
}, "currencies.set")

let hasValidBalance = Computed(@() currenciesBalance.value.findindex(@(val) val < 0) == null)

return {
  currenciesById
  currenciesSorted

  currenciesBalance
  currenciesExpiring
  currenciesPurchases
  hasValidBalance

  currenciesList
}
