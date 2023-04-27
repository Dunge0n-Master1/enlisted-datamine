from "%enlSqGlob/ui_library.nut" import *

let { TextNormal, TextHover, textMargin
} = require("%ui/components/textButton.style.nut")
let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { HighlightFailure } = require("%ui/style/colors.nut")
let { primaryFlatButtonStyle } = require("%enlSqGlob/ui/buttonsStyle.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { notFoundMsg, notFoundHeader, noteStyle
} = require(isNewDesign.value ? "equipDesign.nut" : "equipDesignOld.nut")
let msgbox = require("%enlist/components/msgbox.nut")

let { currenciesById, currenciesBalance } = require("%enlist/currency/currencies.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { buyCurrencyText, openShopByCurrencyId, currencyImage, mkItemCostInfo
} = require("%enlist/currency/purchaseMsgBox.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { curCampItems, curArmyData } = require("%enlist/soldiers/model/state.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let { getShopItemsList, buyShopItemList, barterShopItemList
} = require("%enlist/shop/armyShopState.nut")
let { shopItemByTemplateData } = require("%enlist/preset/presetEquipUtils.nut")

let mkCostInfo = @(price, fullPrice, currencyId) currencyId == null ? null
  : {
      flow = FLOW_VERTICAL
      margin = [bigPadding, 0]
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("preset/equip/buyMsg")
        }.__update(noteStyle)
        mkItemCostInfo(price, fullPrice, currencyId)
      ]
    }

let mkNotEnoughMoney = @(needMoreCurrency, currency) needMoreCurrency > 0 ? {
    flow = FLOW_HORIZONTAL
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("shop/notEnoughCurrency", { priceDiff = needMoreCurrency })
      }.__update(notFoundHeader, { color = HighlightFailure })
      currencyImage(currency)
    ]
  } : null

let mkItemNameList = @(items, showCount) ",\n".join(items.keys().map(function(tpl) {
  let strings = [getItemName(shopItemByTemplateData(tpl))]
  if (showCount && items[tpl] > 1)
    strings.append(loc("common/amountShort", { count = items[tpl] }))
  return " ".join(strings)
}))

let mkNotFound = @(notFoundItems, unavailableItems, priceView, hasDiscountExpired) {
  flow = FLOW_VERTICAL
  children = [
    notFoundItems.len() == 0 ? null : {
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("preset/equip/notFoundMsg")
        }.__update(notFoundHeader)
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = unavailableItems.len() > 0
            ? mkItemNameList(notFoundItems, true)
            : loc("preset/equip/notFoundItems", { items = mkItemNameList(notFoundItems, true) })
        }.__update(notFoundMsg)

        priceView.costInfo
        priceView.notEnoughMoneyInfo

        !hasDiscountExpired ? null : {
          rendObj = ROBJ_TEXT
          text = loc("shop/discount_ended")
        }.__update(notFoundHeader)
      ]
    }

    unavailableItems.len() == 0 ? null : {
      flow = FLOW_VERTICAL
      margin = [bigPadding * 4, 0, 0, 0]
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("preset/equip/buyUnavailable")
        }.__update(notFoundHeader)
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("preset/equip/notFoundItems", { items = mkItemNameList(unavailableItems, true) })
        }.__update(notFoundMsg)
      ]
    }
  ]
}


let mkBuyOrdersBtn = function(barterCost, action) {
  let orders = barterCost.topairs()
  return {
    text = ""
    action = action
    customStyle = {
      textCtor = @(_textField, params, handler, group, sf)
        textButtonTextCtor({
          children = {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            margin = textMargin
            children = mkTextRow(loc("preset/equip/buy"),
              @(text) {
                rendObj = ROBJ_TEXT
                text
                color = sf & S_HOVER ? TextHover : TextNormal
              }.__update(body_txt),
              {
                ["{cost}"] = orders.map(@(payData)  //warning disable: -forgot-subst
                  mkItemCurrency({
                    currencyTpl = payData[0]
                    count = payData[1]
                    textStyle = {
                      color = sf & S_HOVER ? TextHover : TextNormal
                    }.__update(body_txt)
                  }))
              })
          }
        }, params, handler, group, sf)
    }.__update(primaryFlatButtonStyle)
  }
}

let mkBuyButton = @(currency, action, hasDiscountExpiredVal) {
  text = ""
  action = hasDiscountExpiredVal ? null : action
  customStyle = {
    textCtor = @(_textField, params, handler, group, sf)
      textButtonTextCtor({
        children = {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          margin = textMargin
          children = mkTextRow(hasDiscountExpiredVal
            ? loc("preset/equip/priceChanged")
            : loc("preset/equip/buy"),
            @(text) {
              rendObj = ROBJ_TEXT
              color = sf & S_HOVER ? TextHover : TextNormal
              text
            }.__update(body_txt),
            {
              ["{cost}"] = mkCurrency( //warning disable: -forgot-subst
                currency.__update({ //warning disable: -unwanted-modification
                  txtStyle = {
                    color = sf & S_HOVER ? TextHover : TextNormal
                  }.__update(body_txt)
                }))
            })
        }
      }, params, handler, group, sf)
  }.__update(hasDiscountExpiredVal ? {} : primaryFlatButtonStyle)
}

let mkBuyCurrencyBtn = @(currency, action) {
  text = ""
  action
  customStyle = {
    textCtor = @(_textComp, _params, handler, group, sf)
      textButtonTextCtor(buyCurrencyText(currency, sf), h2_txt, handler, group, sf)
  }
}

let missingItemsPriceView = function(notFoundItemsList, unavailableItems,
  onSuccessCb, hasDiscountExpired) {
  let shopItemsTbl = {}

  foreach (itemTpl, count in notFoundItemsList) {
    let shopItem = getShopItemsList(itemTpl)?[0]
    if (shopItem == null) {
      unavailableItems[itemTpl] <- count
      continue
    }
    // can't automatically buy limited items
    // or items above required level
    let { requirements, limit = -1 } = shopItem
    if (limit > 0 || (requirements?.armyLevel ?? 0) > (curArmyData.value?.level ?? 0)) {
      unavailableItems[itemTpl] <- count
      continue
    }

    shopItemsTbl[shopItem.guid] <- {
      shopItem
      count = count + (shopItemsTbl?[shopItem.guid].count ?? 0)
    }
  }

  local hasBarter = true
  local hasBuy = true
  // itemData = { guid = count } - what to buy; for ProfileServer
  // payData**  = { guid = { currency = count } } - what to pay with; for ProfileServer
  // barterTotalCost = { currency = count } - to show the cost in UI
  let itemData = {}
  let payDataBarter = {}
  let barterTotalCost = {}
  let payDataBuy = {}
  local currency = null
  local totalPrice = 0
  local totalFullPrice = 0
  foreach (buyData in shopItemsTbl) {
    let { count, shopItem } = buyData
    let { guid, curItemCost = {}, discountIntervalTs = [] } = shopItem

    itemData[guid] <- count

    hasBarter = hasBarter && curItemCost.len() > 0
    if (hasBarter)
      payDataBarter[guid] <- getPayItemsData(curItemCost, curCampItems.value, count)

    foreach (itemType, cost in curItemCost) {
      barterTotalCost[itemType] <- (barterTotalCost?[itemType] ?? 0) + cost * count
    }

    let { price = 0, fullPrice = 0, currencyId = ""} = shopItem?.curShopItemPrice
    if (currency == null)
      currency = currencyId

    if (discountIntervalTs.len() > 0) {
      // TODO subscribe to price changes that might happen while the dialog is open
    }

    hasBuy = hasBuy && price > 0
    if (price > 0) {
      totalPrice += price * count
      totalFullPrice += fullPrice * count
      payDataBuy[guid] <- { [currencyId] = price }
    }
  }

  hasBuy = hasBuy && totalPrice > 0 && (currenciesBalance.value?[currency] ?? 0) >= totalPrice
  hasBarter = hasBarter && getPayItemsData(barterTotalCost, curCampItems.value) != null

  let applyBtn = {
    text = loc("squads/presets/apply")
    action = onSuccessCb,
    customStyle = primaryFlatButtonStyle
  }

  let buttons = [applyBtn]
  let requestCb = function(isSuccess) {
    if (isSuccess)
      onSuccessCb()
  }
  let shopItemsList = shopItemsTbl.values().map(@(v) v.shopItem)
  if (hasBarter) {
    let action = @() barterShopItemList(shopItemsList, itemData, payDataBarter, requestCb)
    buttons.append(mkBuyOrdersBtn(barterTotalCost, action))
  }
  if (hasBuy) {
    let action = @() buyShopItemList(shopItemsList, itemData, payDataBuy, requestCb)
    buttons.append(mkBuyButton({
      currency = currenciesById.value?[currency]
      price = totalPrice
      fullPrice = totalFullPrice
    }, action, hasDiscountExpired.value))
  } else if (totalPrice > 0) {
    // totalPrice == 0 means this preset includes items that can't be purchased:
    // premium, limited, and default equipment
    buttons.append(mkBuyCurrencyBtn(currenciesById.value?[currency], function() {
      openShopByCurrencyId?[currency]()
    }))
  }
  buttons.append({ text = loc("Cancel"), isCancel = true })

  return {
    buttons
    costInfo = mkCostInfo(totalPrice, totalFullPrice, currency)
    notEnoughMoneyInfo = mkNotEnoughMoney(totalPrice - (currenciesBalance.value?[currency] ?? 0),
      currenciesById.value?[currency])
  }
}

let showNotFoundMsg = function(notFoundPresetItemsVal, onSuccessCb) {
  // shop discounts can expire so the pay buttons must track the time
  // but we deliberately do not subscribe to server time
  // as this would mess up button animations
  let hasDiscountExpired = Watched(false)
  local priceView = {}
  let unavailableItems = {}
  let buttonsWatched = Computed(function() {
    priceView = missingItemsPriceView(notFoundPresetItemsVal, unavailableItems,
      onSuccessCb, hasDiscountExpired)
    return priceView.buttons
  })

  let canBuyList = notFoundPresetItemsVal.filter(@(_count, tpl) tpl not in unavailableItems)
  msgbox.showMessageWithContent({
    content = mkNotFound(canBuyList, unavailableItems, priceView, hasDiscountExpired.value)
    buttons = buttonsWatched
  })
}

return {
  showNotFoundMsg
}
