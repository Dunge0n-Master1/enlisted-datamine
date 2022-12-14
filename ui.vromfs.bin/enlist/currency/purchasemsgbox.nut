from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let checkbox = require("%ui/components/checkbox.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { currenciesById, currenciesBalance } = require("%enlist/currency/currencies.nut")
let { dontShowToday, setDontShowTodayByKey } = require("%enlist/options/dontShowAgain.nut")
let colorize = require("%ui/components/colorize.nut")
let colors = require("%ui/style/colors.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { priceWidget } = require("%enlist/components/priceWidget.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { purchaseButtonStyle } = require("%enlSqGlob/ui//buttonsStyle.nut")
let { mkCurrency } = require("currenciesComp.nut")


let defGap = fsh(3)
let currencySize = hdpx(29)
let openShopByCurrencyId = {}

let mkItemDescription = @(description) makeVertScroll({
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = description
  }.__update(body_txt)
  {
    size = [flex(), SIZE_TO_CONTENT]
    maxHeight = hdpx(300)
    styling = thinStyle
  })

let currencyImage = @(currency) currency
  ? {
      size = [currencySize, currencySize]
      rendObj = ROBJ_IMAGE
      image = Picture(currency.image(currencySize))
    }
  : null

let function mkItemCostInfo(price, fullPrice, currencyId) {
  let currency = currenciesById.value?[currencyId]
  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = "{0} ".subst(loc("shop/willCostYou"))
      }.__update(sub_txt)
      mkCurrency({
        currency
        price
        fullPrice
        iconSize = hdpx(20)
      })
    ]
  }
}

let function buyCurrencyText(currency, sf) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
    gap = currencyImage(currency)
    children = loc("btn/buyCurrency").split("{currency}").map(@(text) {
      rendObj = ROBJ_TEXT
      color = colors.textColor(sf, false, colors.TextActive)
      text
    }.__update(body_txt))
  }
}

let notEnoughMoneyInfo = @(price, currencyId) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      color = colors.HighlightFailure
      text = loc("shop/notEnoughCurrency", {
        priceDiff = price - (currenciesBalance.value?[currencyId] ?? 0)
      })
    }.__update(body_txt)
    currencyImage(currenciesById.value?[currencyId])
  ]
}

local function show(price, currencyId, purchase, fullPrice = null, title = "", productView = null,
  description = null, purchaseCurrency = null, dontShowMeTodayId = null, srcWindow = null,
  srcComponent = null, alwaysShowCancel = false, showOnlyWhenNotEnoughMoney = false,
  gap = defGap, additionalButtons = [], purchaseText = null
) {
  let bqBuyCurrency = @() sendBigQueryUIEvent("action_buy_currency", srcWindow, srcComponent)
  let currency = currenciesById.value?[currencyId]
  purchaseCurrency = purchaseCurrency ?? openShopByCurrencyId?[currencyId]

  if (!(price instanceof Watched))
    price = Watched(price)
  if (!(fullPrice instanceof Watched))
    fullPrice = Watched(fullPrice)

  let notEnoughMoney = currency == null
    ? Watched(false)
    : Computed(@() (currenciesBalance.value?[currencyId] ?? 0) < price.value)

  if (showOnlyWhenNotEnoughMoney && !notEnoughMoney.value) {
    purchase()
    bqBuyCurrency()
    return
  }

  local dontShowCheckbox = null
  if (dontShowMeTodayId != null && !notEnoughMoney.value) {
    let dontShowMeToday = Computed(@() dontShowToday.value?[dontShowMeTodayId] ?? false)
    if (dontShowMeToday.value) {
      purchase()
      bqBuyCurrency()
      return
    }
    dontShowCheckbox = checkbox(dontShowMeToday, loc("dontShowMeAgainToday"),
      { setValue = @(v) setDontShowTodayByKey(dontShowMeTodayId, v) })
  }

  let buttons = Computed(function() {
    if (!notEnoughMoney.value)
      return [{
        text = purchaseText ?? loc("btn/buy")
        action = function() {
          purchase()
          bqBuyCurrency()
        }
        customStyle = {
          hotkeys = [[ "^J:Y | Enter", { description = {skip = true}} ]]
        }.__update(purchaseButtonStyle)
      }]
      .extend(alwaysShowCancel ? [{ text = loc("Cancel") }] : [])
      .extend(additionalButtons)

    let res = []
    if (purchaseCurrency != null)
      res.append({
        customStyle = {
          textCtor = function(textComp, params, handler, group, sf) {
            textComp = buyCurrencyText(currency, sf)
            params = h2_txt
            return textButtonTextCtor(textComp, params, handler, group, sf)
          }
        },
        action = function() {
          purchaseCurrency()
          sendBigQueryUIEvent("event_low_currency", srcWindow, srcComponent)
        }
      })
    res.extend(additionalButtons)
    if (alwaysShowCancel || purchaseCurrency == null)
      res.append({ text = loc("Cancel") })
    return res
  })

  let params = {
    text = colorize(colors.MsgMarkedText, title)
    fontStyle = body_txt
    children = {
      size = [fsh(80), SIZE_TO_CONTENT]
      margin = [defGap, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap
      children = [
        productView
        typeof description == "string" ? mkItemDescription(description) : description
        @() {
          watch = [price, fullPrice, notEnoughMoney]
          halign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            mkItemCostInfo(price.value, fullPrice.value, currencyId)
            notEnoughMoney.value
              ? notEnoughMoneyInfo(price.value, currencyId)
              : dontShowCheckbox
          ]
        }
      ]
    }
    topPanel = currencyId in currenciesById.value
      ? priceWidget(currenciesBalance.value?[currencyId] ?? loc("currency/notAvailable"), currencyId)
          .__update({
            size = [SIZE_TO_CONTENT, flex()]
            gap = hdpx(10)
          })
      : null
    buttons
  }

  msgbox.showWithCloseButton(params)
  sendBigQueryUIEvent("open_buy_currency_window", srcWindow, srcComponent)
}

return {
  purchaseMsgBox = kwarg(show)
  openShopByCurrencyId
  setOpenShopFunctions = @(list) openShopByCurrencyId.__update(list)
}