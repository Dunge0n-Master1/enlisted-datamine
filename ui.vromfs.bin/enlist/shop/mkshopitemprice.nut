from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  bigPadding, bonusColor, defTxtColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { curCampItemsCount } = require("%enlist/soldiers/model/state.nut")
let { mkItemCurrency } = require("currencyComp.nut")
let {
  mkCurrency, mkCurrencyCount, oldPriceLine
} = require("%enlist/currency/currenciesComp.nut")


let function hasItemsToBarter(curItemCost, campItems) {
  if (curItemCost.len() == 0)
    return false

  foreach (itemTpl, reqCount in curItemCost)
    if ((campItems?[itemTpl] ?? 0) < reqCount)
      return false

  return true
}

let mkPriceText = @(price, currencyId) loc($"priceText/{currencyId}",
  { price }, $"{price}{currencyId}")

let mkItemPurchaseInfo = kwarg(
  function(curItemCost, campItems, curShopItemPrice, currencies,
    shop_price_curr = "", shop_price = 0, shop_price_full = 0
  ) {

    let hasBarter = hasItemsToBarter(curItemCost, campItems)
    let hasDiscount = curShopItemPrice.fullPrice > curShopItemPrice.price

    if (hasBarter && !hasDiscount)
      return txt({
        text = loc("mainmenu/receive")
        color = activeTxtColor
      }.__update(body_txt))

    let { price, fullPrice, currencyId = null } = curShopItemPrice
    let currency = currencies.findvalue(@(c) c.id == currencyId)
    if (currency != null && price > 0)
      return {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = bigPadding
        children = [
          txt({
            text = loc("mainmenu/buyFor")
            color = activeTxtColor
          }.__update(sub_txt))
          mkCurrency({
            currency
            price
            fullPrice
          })
        ]
      }

    // this block for console platform specific prices:
    if (shop_price_curr != "" && shop_price > 0) {
      let hasConsoleDiscount = shop_price_full > shop_price
      return {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = bigPadding
        children = [
          txt({
            text = loc("mainmenu/buyFor")
            color = activeTxtColor
          }.__update(sub_txt))
          mkCurrencyCount(
            mkPriceText(shop_price, shop_price_curr),
            { color = hasConsoleDiscount ? bonusColor : activeTxtColor }
          )
          !hasConsoleDiscount ? null
            : {
                children = [
                  mkCurrencyCount(mkPriceText(shop_price_full, shop_price_curr),
                    { color = defTxtColor })
                  oldPriceLine.__merge({ color = defTxtColor })
                ]
              }
        ]
      }
    }

    return null
  })

let mkItemBarterInfo = kwarg(function(guid, curItemCost, campItems) {
  let children = []
  foreach (itemTpl, reqCount in curItemCost) {
    let inStock = campItems?[itemTpl] ?? 0
    children.append(mkItemCurrency({
      currencyTpl = itemTpl
      count = $"{inStock}/{reqCount}"
      keySuffix = guid
      textStyle = (inStock >= reqCount
        ? { color = bonusColor,  }
        : {}).__update(body_txt)
    }))
  }
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children
  }
})

let mkPrice = @(shopItem, bgParams = {}, needPriceText = true,
  showGoldPrice = true, styleOverride = {}
) function() {
    if (shopItem?.isPriceHidden ?? false)
      return null
    let children = []
    foreach (itemTpl, value in shopItem.curItemCost)
      children.append(mkItemCurrency({
        currencyTpl = itemTpl, count = value, keySuffix = shopItem.guid, textStyle = styleOverride
      }))
    if (showGoldPrice) {
      let { curShopItemPrice } = shopItem
      let { price, fullPrice, currencyId = null } = curShopItemPrice
      let currency = currenciesList.value.findvalue(@(c) c.id == currencyId)
      if (currency != null && price > 0) {
        if (children.len() > 0)
          children.append(txt({ text = loc("mainmenu/or")}.__update(body_txt)))
        children.append(mkCurrency({
          currency
          price
          fullPrice
        }))
      }
    }

    if (children.len() == 0) {
      let { shop_price_curr = "", shop_price = 0 } = shopItem
      children.append(txt({
        text = loc($"priceText/{shop_price_curr}", { price = shop_price }, $"{shop_price}{shop_price_curr}")
      }.__update(body_txt)))
    }

    if (needPriceText && children.len() > 0)
      children.insert(0, txt({ text = loc("price")}.__update(body_txt)))

    return {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = children
    }.__update(bgParams)
  }

local function mkShopItemPrice(shopItem, personalOffer = null) {
  let {
    guid, curItemCost, curShopItemPrice, shop_price_curr = "",
    shop_price = 0, shop_price_full = 0
  } = shopItem

  let shopItemPrice = clone curShopItemPrice
  if (personalOffer != null) {
    let { fullPrice } = shopItemPrice
    let { discountInPercent = 0 } = personalOffer
    shopItemPrice.price = fullPrice - fullPrice * discountInPercent / 100
  }

  return @() {
    watch = [curCampItemsCount, currenciesList]
    size = flex()
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      mkItemBarterInfo({
        guid
        curItemCost
        campItems = curCampItemsCount.value
      })
      mkItemPurchaseInfo({
        curItemCost
        curShopItemPrice = shopItemPrice
        shop_price_curr
        shop_price
        shop_price_full
        campItems = curCampItemsCount.value
        currencies = currenciesList.value
      })
    ]
  }
}

return {
  mkShopItemPrice
  mkPrice = kwarg(mkPrice)
}
