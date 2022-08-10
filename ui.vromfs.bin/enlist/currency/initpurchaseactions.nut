from "%enlSqGlob/ui_library.nut" import *

let { setOpenShopFunctions } = require("%enlist/currency/purchaseMsgBox.nut")
let { buyCurrency } = require("%enlist/shop/armyShopState.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")

let function initActions() {
  let actions = {}
  foreach (currency in currenciesList.value) {
    let c = currency
    let { id, purchaseUrl = "" } = c
    if (purchaseUrl != "")
      actions[id] <- @() buyCurrency(c)
  }
  setOpenShopFunctions(actions)
}

initActions()
currenciesList.subscribe(@(_) initActions())