from "%enlSqGlob/ui_library.nut" import *

let {btnTranspTextColor, TextActive} = require("%ui/style/colors.nut")
let { currenciesBalance, currenciesSorted } = require("%enlist/currency/currencies.nut")
let { buyCurrency } = require("%enlist/shop/armyShopState.nut")
let { gap } = require("%enlSqGlob/ui/viewConst.nut")
let { mkCurrency, mkCurrencyTooltip } = require("currenciesComp.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { is_pc } = require("%dngscripts/platform.nut")

let function currencyBalance(currency) {
  let stateFlags = Watched(0)
  return @() {
    watch = [currenciesBalance, stateFlags]
    size = [SIZE_TO_CONTENT, flex()]
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    disableInput = is_pc && (currency?.purchaseUrl ?? "") == ""
    onClick = @() buyCurrency(currency)
    onHover = @(on) setTooltip(on ? mkCurrencyTooltip(currency) : null)

    children = mkCurrency({
      currency
      price = currenciesBalance.value?[currency.id]
      txtStyle = { color = btnTranspTextColor(stateFlags.value, false, TextActive) }
      iconSize = hdpx(30)
    })
  }
}

let function currenciesWidget() {
  let visibleCurrencies = currenciesSorted.value.filter(@(currency) currency?.visible.value ?? true)
  return {
    key = "currenciesWidget"
    watch = currenciesSorted
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_HORIZONTAL
    gap = gap
    children = visibleCurrencies.map(currencyBalance)
  }
}

return currenciesWidget
