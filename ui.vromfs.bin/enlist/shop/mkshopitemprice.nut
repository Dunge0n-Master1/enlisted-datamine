from "%enlSqGlob/ui_library.nut" import *

let { utf8ToUpper } = require("%sqstd/string.nut")
let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, bonusColor, defTxtColor, activeTxtColor, titleTxtColor, discountBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { curCampItemsCount } = require("%enlist/soldiers/model/state.nut")
let { mkItemCurrency } = require("currencyComp.nut")
let { mkCurrency, mkCurrencyCount, oldPriceLine } = require("%enlist/currency/currenciesComp.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { mkHeaderFlag, primeFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { shopItemContentCtor } = require("%enlist/shop/armyShopState.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")


let sidePadding = fsh(2)
let discountBannerHeight = hdpx(48) // equal to PRICE_HEIGHT!


let function hasItemsToBarter(curItemCost, campItems) {
  if (curItemCost.len() == 0)
    return false

  foreach (itemTpl, reqCount in curItemCost)
    if ((campItems?[itemTpl] ?? 0) < reqCount)
      return false

  return true
}

let mkPriceText = @(price, currencyId) loc($"priceText/{currencyId}", { price })

let mkPurchaseText = @(isSoldier) isSoldier ? loc("mainmenu/enlistFor") : loc("mainmenu/buyFor")

let function mkItemPurchaseInfo(shopItem, campItems, currencies, isNarrow) {
  let { curItemCost, curShopItemPrice, shop_price_curr = "",
    shop_price = 0, shop_price_full = 0, discountInPercent = 0,
    isPriceHidden = false
  } = shopItem

  let hasBarter = hasItemsToBarter(curItemCost, campItems)
  let hasDiscount = curShopItemPrice.fullPrice > curShopItemPrice.price
  let isSoldier = (shopItemContentCtor(shopItem)?.value.content.soldierClasses.len() ?? 0) > 0
  if (hasBarter && !hasDiscount)
    return txt({
      text = isSoldier ? loc("mainmenu/enlist") : loc("mainmenu/receive")
      color = activeTxtColor
      padding = [0, sidePadding, 0, 0]
    }.__update(body_txt))

  let { price, fullPrice, currencyId = null } = curShopItemPrice
  //block for Ingame Currencies: Gold, etc
  let currency = currencies.findvalue(@(c) c.id == currencyId)
  if (currency != null && (price > 0 || discountInPercent > 0))
    return {
      flow = FLOW_HORIZONTAL
      padding = [0, sidePadding, 0, 0]
      valign = ALIGN_CENTER
      gap = bigPadding
      children = [
        isNarrow || isPriceHidden ? null
          : txt({
              text = mkPurchaseText(isSoldier)
              color = activeTxtColor
            }.__update(sub_txt))
        mkDiscountWidget(discountInPercent)
        isPriceHidden ? null : mkCurrency({
          currency
          price
          fullPrice
        })
      ]
    }

  // this block for external store:
  if (shop_price_curr != "" && shop_price > 0) {
    let hasStoreDiscount = shop_price_full > shop_price
    let children = []
    if (!isPriceHidden) {
      if (!isNarrow || !hasStoreDiscount)
        children.append(txt({
          text = mkPurchaseText(isSoldier)
          color = activeTxtColor
        }.__update(sub_txt)))

      children.append(mkCurrencyCount(
        mkPriceText(shop_price, shop_price_curr),
        { color = hasStoreDiscount ? bonusColor : activeTxtColor }
      ))

      if (hasStoreDiscount)
        children.append({children = [
          mkCurrencyCount(mkPriceText(shop_price_full, shop_price_curr), { color = defTxtColor })
          oldPriceLine.__merge({ color = defTxtColor })
        ]})
    }
    children.append(mkDiscountWidget(discountInPercent))

    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = bigPadding
      padding = [0, sidePadding, 0, 0]
      children
    }
  }

  return null
}

let function mkItemBarterInfo(shopItem, campItems) {
  let { guid, curItemCost } = shopItem
  if (curItemCost.len() == 0)
    return null

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
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    padding = [0,0,0,sidePadding]
    children
  }
}

let mkPrice = @(shopItem, bgParams = {}, needPriceText = true,
  showGoldPrice = true, styleOverride = {}
) shopItem?.isPriceHidden ?? false ? null : function() {
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
        text = loc($"priceText/{shop_price_curr}", { price = shop_price })
      }.__update(body_txt)))
    }

    if (needPriceText && children.len() > 0)
      children.insert(0, txt({ text = loc("price")}.__update(body_txt)))

    return {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children
    }.__update(bgParams)
  }

let function mkDiscountInfo(discountData) {
  if (discountData == null)
    return null

  let { locId, endTime = 0 } = discountData
  return {
    size = flex()
    valign = ALIGN_BOTTOM
    children = mkHeaderFlag({
      size = [SIZE_TO_CONTENT, discountBannerHeight]
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      padding = [0, fsh(5), 0, fsh(1)]
      children = [
        txt({
          text = utf8ToUpper(loc(locId))
          color = titleTxtColor
        }.__update(sub_txt))
        endTime == 0 ? null : mkCountdownTimer({ timestamp = endTime })
      ]
    }, primeFlagStyle.__merge({
      size = SIZE_TO_CONTENT
      offset = 0
      flagColor = discountBgColor
    }))
  }
}

local function mkShopItemPrice(shopItem, personalOffer = null, isNarrow = false) {
  local {
    curItemCost, curShopItemPrice, shop_price_curr = "",
    shop_price = 0, discountInPercent = 0,
    discountIntervalTs = [], isPriceHidden = false
  } = shopItem
  let { price } = curShopItemPrice
  let [ beginTime = 0, endTime = 0 ] = discountIntervalTs
  let isDiscountActive = beginTime > 0
    && beginTime <= serverTime.value
    && (serverTime.value <= endTime || endTime == 0)
  let discountData = personalOffer != null ? {
        endTime = personalOffer.endTime
        locId = "specialOfferShort"
      }
    : discountInPercent > 0 || (discountInPercent == 0 && isDiscountActive) ? {
        endTime
        locId = "shop/discountNotify"
      }
    : null

  if (discountData == null
    && curItemCost.len() == 0
    && price == 0
    && discountInPercent == 0
    && (shop_price_curr == "" || shop_price == 0 || isPriceHidden))
      return null

  return @() {
    watch = [curCampItemsCount, currenciesList]
    size = flex()
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      mkItemBarterInfo(shopItem, curCampItemsCount.value)
      mkDiscountInfo(discountData)
      { size = flex() }
      mkItemPurchaseInfo(shopItem, curCampItemsCount.value, currenciesList.value, isNarrow)
    ]
  }
}

return {
  mkShopItemPrice
  mkPrice = kwarg(mkPrice)
}
