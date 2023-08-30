from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { Flat } = require("%ui/components/textButton.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let { TextHover, TextNormal, TextDisabled } = require("%ui/components/textButton.style.nut")
let { HighlightFailure } = require("%ui/style/colors.nut")

let canUseOrder = @(orderTpl, orderCount, campItems) (orderTpl ?? "") != ""
  && (orderCount ?? 0) > 0
  && (campItems?[orderTpl] ?? 0) >= orderCount

let txtColor = @(sf, isEnabled) !isEnabled ? TextDisabled
  : sf & S_HOVER ? TextHover
  : TextNormal

let function mkCurrencyButton(
  text, cb, campItems, cost = null, orderTpl = null, orderCount = null,
  isEnabled = true, override = {}
) {
  let isEnough = (campItems?[orderTpl] ?? 0) >= (orderCount ?? 0)
  let priceCtor = canUseOrder(orderTpl, orderCount, campItems) || cost == null
    ? @(sf) mkItemCurrency({
        currencyTpl = orderTpl
        count = orderCount
        textStyle = { color = isEnough ? txtColor(sf, isEnabled) : HighlightFailure }
      })
    : @(sf) mkCurrency({
        currency = enlistedGold
        price = cost
        txtStyle = { color = txtColor(sf, isEnabled) }
      })
  return Flat(text, cb, {
    textCtor = @(textField, params, handler, group, sf) textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = hdpx(7)
      gap = hdpx(10)
      children = [
        textField.__merge({ margin = 0 })
        priceCtor(sf)
      ]
    }, params, handler, group, sf)
    textParams = fontBody
    hplace = ALIGN_CENTER
    margin = 0
    isEnabled
  }.__update(override))
}

return {
  canUseOrder
  mkCurrencyButton = kwarg(mkCurrencyButton)
}