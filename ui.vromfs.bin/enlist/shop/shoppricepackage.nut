from "%enlSqGlob/ui_library.nut" import *


let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { curCampItemsCount } = require("%enlist/soldiers/model/state.nut")
let { mkCurrency, mkCurrencyCount } = require("%enlist/currency/currenciesComp.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { defTxtColor, titleTxtColor, colPart, columnGap
} = require("%enlSqGlob/ui/designConst.nut")
let { mkItemCurrency } = require("currencyComp.nut")


let priceSize = [colPart(4), colPart(0.8)]

let transpLineColor    = 0x00000000
let realPriceLineColor = 0xFF334E80
let goldPriceLineColor = 0xFF6E0F0F
let mixPriceLineColor  = 0xFF797979

let realPriceGradient = mkColoredGradientX(realPriceLineColor, transpLineColor)
let goldPriceGradient = mkColoredGradientX(goldPriceLineColor, transpLineColor)
let mixPriceGradient  = mkColoredGradientX(mixPriceLineColor, transpLineColor)

let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)


let priceSeparator = {
  padding = [0, columnGap]
  valign = ALIGN_BOTTOM
  rendObj = ROBJ_TEXT
  text = loc("mainmenu/or")
}.__update(defTxtStyle)

let mkPriceLine = @(bgImg) {
  size = [flex(), ph(8)]
  rendObj = ROBJ_IMAGE
  image = bgImg
}

let mkPriceBar = @(bgImg, children) {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = priceSeparator
  padding = [0, columnGap]
  valign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = bgImg
  children
}

let shopPriceFrame = @(bgImg, priceContent) {
  size = flex()
  flow = FLOW_VERTICAL
  gap = { size = [flex(), ph(5)]}
  children = [
    mkPriceLine(bgImg)
    mkPriceBar(bgImg, priceContent)
    mkPriceLine(bgImg)
  ]
}


let mkPriceText = @(price, currencyId) loc($"priceText/{currencyId}",
  { price }, $"{price}{currencyId}")

let function mkItemPurchaseInfo(currencies, currencyPrice, shop_price_curr, shop_price) {
  let { price, fullPrice, currencyId = null } = currencyPrice
  let currency = currencies.findvalue(@(c) c.id == currencyId)
  if (currency != null && price > 0)
    return mkCurrency({ currency, price, fullPrice })

  // this block for console platform specific prices:
  if (shop_price_curr != "" && shop_price > 0)
    return mkCurrencyCount(mkPriceText(shop_price, shop_price_curr), {})

  return null
}

let function mkItemBarterInfo(guid, curItemCost, campItems) {
  let children = []
  foreach (itemTpl, reqCount in curItemCost) {
    let inStock = campItems?[itemTpl] ?? 0
    children.append(mkItemCurrency({
      currencyTpl = itemTpl
      count = $"{reqCount}"
      keySuffix = guid
      textStyle = inStock >= reqCount
        ? defTxtStyle
        : titleTxtStyle
    }))
  }
  return children.len() == 0 ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = columnGap
        children
      }
}


let function mkShopItemPrice(shopItem, lockObject) {
  let { guid, curItemCost, curShopItemPrice,
    shop_price_curr = "", shop_price = 0
  } = shopItem
  let { price, currencyId = null } = curShopItemPrice
  let hasRealPrice = shop_price_curr != "" && shop_price > 0
  let hasGoldPrice = currencyId != null && price > 0
  let hasItemPrice = curItemCost.len() > 0
  let bgImg = hasRealPrice ? realPriceGradient
    : hasGoldPrice && !hasItemPrice ? goldPriceGradient
    : mixPriceGradient

  if (lockObject != null)
    return shopPriceFrame(bgImg, lockObject).__update({ size = priceSize })

  let currencyObj = mkItemPurchaseInfo(
    currenciesList.value,
    curShopItemPrice,
    shop_price_curr,
    shop_price
  )

  let barterObj = mkItemBarterInfo(guid, curItemCost, curCampItemsCount.value)

  return @() {
    watch = [curCampItemsCount, currenciesList]
    size = priceSize
    children = currencyObj == null && barterObj == null ? null
      : shopPriceFrame(bgImg, [currencyObj, barterObj])
  }
}

return {
  mkShopItemPrice
}
