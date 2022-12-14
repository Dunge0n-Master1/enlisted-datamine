from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt, body_bold_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let { mkPrice } = require("%enlist/shop/mkShopItemPrice.nut")
let { doesLocTextExist } = require("dagor.localize")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { isProductionCircuit } = require("%dngscripts/appInfo.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { mkItemCurrency, mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let { sound_play } = require("sound")
let { HighlightFailure, MsgMarkedText, TextActive, TextHighlight, textColor
} = require("%ui/style/colors.nut")
let { bigPadding, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { viewShopInfoBtnStyle, DISCOUNT_WARN_TIME } = require("shopPkg.nut")
let {
  barterShopItem, buyItemByGuid, getBuyRequirementError, buyItemByStoreId, buyShopItem,
  realCurrencies, shopItemContentCtor, buyShopOffer
} = require("armyShopState.nut")
let { shopItems } = require("shopItems.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { currenciesById, currenciesBalance } = require("%enlist/currency/currencies.nut")
let { purchaseButtonStyle, primaryFlatButtonStyle
} = require("%enlSqGlob/ui/buttonsStyle.nut")
let colorize = require("%ui/components/colorize.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")
let { priceWidget } = require("%enlist/components/priceWidget.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { openShopByCurrencyId } = require("%enlist/currency/purchaseMsgBox.nut")
let { allActiveOffers } = require("%enlist/offers/offersState.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { openBPwindow, getRewardIdx } = require("%enlist/battlepass/bpWindowState.nut")


enum DISCOUNT_STATE {
  STARTED = 0
  ENDING = 1
  ENDED = 2
}

let defGap = fsh(3)
let currencySize = hdpx(29)

let mkDescription = @(descLocId) descLocId == null ? null
  : noteTextArea(loc(descLocId)).__update({
      halign = ALIGN_CENTER
    }.__update(sub_txt))

let function mkResourcesLackInfo(reqResources, viewCurrs, costLocId) {
  let lackResources = []
  foreach (currencyTpl, required in reqResources) {
    let count = required - (viewCurrs?[currencyTpl] ?? 0)
    if (count > 0)
      lackResources.append(mkItemCurrency({
        currencyTpl, count, textStyle = { color = HighlightFailure }.__update(body_bold_txt)
      }))
  }

  if (lackResources.len() == 0)
    return null

  return {
    size = [fsh(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        children = [
          txt({
            text = loc("shop/notEnoughCurrency", { priceDiff = "" })
            color = HighlightFailure
          }.__update(body_txt))
          {
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            children = lackResources
          }
        ]
      }
      noteTextArea(loc(costLocId)).__update({
        halign = ALIGN_CENTER
        color = TextActive
      }, sub_txt)
    ]
  }
}

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

let mkAllPricesView = @(barterPriceView, buyPriceView) barterPriceView || buyPriceView
  ? {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          text = "{0} ".subst(loc("shop/willCostYou"))
        }.__update(sub_txt)
        barterPriceView
        !(barterPriceView && buyPriceView) ? null : {
          rendObj = ROBJ_TEXT
          text = loc("mainmenu/or")
        }.__update(sub_txt)
        buyPriceView
      ]
    }
  : null

let mkBarterCurrency = @(barterTpl){
  size = [SIZE_TO_CONTENT, flex()]
  minHeight = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    mkCurrencyImage(getCurrencyPresentation(barterTpl)?.icon)
    @(){
      watch = realCurrencies
      padding = [0, hdpx(3)]
      rendObj = ROBJ_TEXT
      text = realCurrencies.value?[barterTpl]
    }.__update(body_txt)
  ]
}

let btnWithCurrImageComp = @(text, currImgs, price, sf, count, shopItemPriceInc) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  margin = [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
  gap = hdpx(10)
  children = [
    {
      rendObj = ROBJ_TEXT
      color = textColor(sf, false, TextActive)
      text
    }.__update(body_txt)
    currImgs
    {
      rendObj = ROBJ_TEXT
      color = textColor(sf, false, TextActive)
      text = count * price
        + shopItemPriceInc * count * (count - 1) / 2
    }.__update(body_txt)
  ]
}

let notEnoughMoneyInfo = @(price, currencyId) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      color = HighlightFailure
      text = loc("shop/notEnoughCurrency", {
        priceDiff = price - (currenciesBalance.value?[currencyId] ?? 0)
      })
    }.__update(body_txt)
    currencyImage(currenciesById.value?[currencyId])
  ]
}

let function buyCurrencyText(currency, sf) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
    gap = currencyImage(currency)
    children = loc("btn/buyCurrency").split("{currency}").map(@(text) {
      rendObj = ROBJ_TEXT
      color = textColor(sf, false, TextActive)
      text
    }.__update(body_txt))
  }
}

let mkDiscountInfo = @(state) !state ? null : {
  rendObj = ROBJ_TEXT
  text = state == DISCOUNT_STATE.STARTED ? loc("shop/discount_started")
    : state == DISCOUNT_STATE.ENDING ? loc("shop/discount_ending")
    : loc("shop/discount_ended")
  color = state == DISCOUNT_STATE.STARTED ? TextHighlight : HighlightFailure
}.__update(body_txt)

let function recalcOfferPrice(offers, offerGuid, price, fullPrice, discountState, ts) {
  let offer = offers.findvalue(@(o) o.guid == offerGuid)
  if (offer == null)
    return discountState(DISCOUNT_STATE.ENDED)

  let { endTime = 0, discountInPercent = 0 } = offer
  if (discountInPercent <= 0)
    return discountState(DISCOUNT_STATE.ENDED)

  price(fullPrice.value - fullPrice.value * discountInPercent / 100)
  let newState = endTime <= ts ? DISCOUNT_STATE.ENDED
    : endTime - ts < DISCOUNT_WARN_TIME ? DISCOUNT_STATE.ENDING
    : DISCOUNT_STATE.STARTED
  discountState(newState)
}

let function notEnoughMsg(itemTpl, missingOrders) {
  let descId = $"dontHaveEnoughOrders/{itemTpl}"
  msgbox.showMsgbox({
    children = doesLocTextExist(descId)
      ? {
          rendObj = ROBJ_TEXTAREA
          size = [sw(70), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          text = descId
        }.__update(h2_txt)
      : {
        flow = FLOW_VERTICAL
        size = [sw(70), SIZE_TO_CONTENT]
        gap = hdpx(15)
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("notEnoughOrders")
          }.__update(h2_txt)
          {
            flow = FLOW_HORIZONTAL
            children = [
              {
                rendObj = ROBJ_TEXT
                text = loc("needMoreOrders")
              }.__update(h2_txt)
              {
                rendObj = ROBJ_TEXT
                margin = [0, 0, 0, hdpx(10)]
                text = missingOrders
                color = HighlightFailure
              }.__update(h2_txt)
              mkCurrencyImage(getCurrencyPresentation(itemTpl)?.icon)
            ]
          }
          {
            rendObj = ROBJ_TEXTAREA
            size = [flex(), SIZE_TO_CONTENT]
            behavior = Behaviors.TextArea
            text = loc("dontHaveEnoughOrders")
          }.__update(h2_txt)
        ]
      }
  })
}

let titleLocalization = @(locId, shopItem) loc(locId, { purchase = loc(shopItem?.nameLocId) ?? "" })

let function buyItem(shopItem, productView = null, viewBtnCb = null,
  activatePremiumBttn = null, description = null, pOfferGuid = null, countWatched = Watched(1)
) {
  // no free space for soldier:
  let requiredInfo = getBuyRequirementError(shopItem)
  if (requiredInfo != null) {
    let buttons = [{ text = loc("Ok"), isCancel = true }]
    if (requiredInfo.solvableByPremium && activatePremiumBttn!=null)
      buttons.append(activatePremiumBttn)
    if (requiredInfo?.resolveCb != null)
      buttons.append({ text = requiredInfo.resolveText,
        action = requiredInfo.resolveCb,
        isCurrent = true })
    return msgbox.show({ text = requiredInfo.text, buttons })
  }

  let {
    curItemCost = {}, referralLink = "", discountIntervalTs = [], shopItemPriceInc = 0
  } = shopItem
  let hasBarter = curItemCost.len() > 0
  let barterInfo = Computed(@() getPayItemsData(curItemCost, curCampItems.value))

  local { price = 0, fullPrice = 0, currencyId = ""} = shopItem?.curShopItemPrice
  let currency = currenciesById.value?[currencyId]
  if (!(price instanceof Watched))
      price = Watched(price)
  if (!(fullPrice instanceof Watched))
    fullPrice = Watched(fullPrice)

  let ts = serverTime.value
  let discountState = Watched(null)
  if (pOfferGuid != null) {
    allActiveOffers.subscribe(function(offers) {
      recalcOfferPrice(offers, pOfferGuid, price, fullPrice, discountState, serverTime.value)
    })
    recalcOfferPrice(allActiveOffers.value, pOfferGuid, price, fullPrice, discountState, ts)
  }
  else if (discountIntervalTs.len() > 0){
    local [from, to = 0] = discountIntervalTs
    if (ts < from || ts < to){
      shopItems.subscribe(function(items){
        let curShopItem = items?[shopItem.guid]
        let curPrice = curShopItem?.curShopItemPrice.price ?? 0
        if (curPrice != price.value){
          discountState(curPrice > price.value ? DISCOUNT_STATE.ENDED : DISCOUNT_STATE.STARTED)
          price(curPrice)
        }
      })
      if (to > 0) {
        if (to - ts > DISCOUNT_WARN_TIME){
          gui_scene.resetTimeout(to - ts - DISCOUNT_WARN_TIME,
            @() discountState(DISCOUNT_STATE.ENDING))
        } else {
          discountState(DISCOUNT_STATE.ENDING)
        }
      }
    }
  }

  let hasBuy = Computed(@() price.value > 0)
  let hasOfferExpired = Computed(@() pOfferGuid != null
    && discountState.value == DISCOUNT_STATE.ENDED)

  let hasSquads = (shopItem?.squads.len() ?? 0) > 0
  let isSoldier = (shopItemContentCtor(shopItem)?.value.content.soldierClasses.len() ?? 0) > 0
  local title = isSoldier ? titleLocalization("shop/wantPurchaseSoldier", shopItem)
    : !hasSquads ? titleLocalization("shop/wantPurchaseMsg", shopItem)
    : shopItem?.nameLocId ? loc(shopItem.nameLocId)
    : ", ".join(shopItem.squads.map(@(sq) loc(squadsPresentation?[sq.armyId][sq.id].titleLocId)))

  local costLocId = "shop/noItemsToPay"

  if (hasBarter)
    foreach (cur, _ in curItemCost) {
      let curLocId = $"items/{cur}/acquire"
      let locId = $"shop/noItemsToPay/{cur}"

      if (doesLocTextExist(curLocId))
        title = $"{title}\n{loc(curLocId)}"

      if (doesLocTextExist(locId))
        costLocId = locId
    }

  let srcComponent = hasSquads ? "buy_squad_window" : "buy_shop_item"

  let buyCb = hasSquads ? null
    : function(isSuccess){
      if (isSuccess)
        sound_play("ui/purchase_additional_squad")
    }

  let msgBoxContent = function(){
    local barterPriceView = null
    local buyPriceView = null
    let msgBody = [
      productView ?? mkDescription(shopItem?.descLocId)
      typeof description == "string" ? mkItemDescription(description) : description
    ]

    // barter area
    if (hasBarter){
      if (!barterInfo.value){
        msgBody.append(mkResourcesLackInfo(curItemCost, realCurrencies.value, costLocId))
        if (currencyId == "EnlistedGold" && price.value > 0) {
          msgBody.append({
            size = [fsh(50), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            margin = bigPadding
            children = [
              noteTextArea(loc("buy/forEnlistedGold")).__update({
                halign = ALIGN_CENTER
                color = MsgMarkedText
              }, sub_txt)
            ]
          })
        }
      } else {
        barterPriceView = mkPrice({
          shopItem
          needPriceText = false
          showGoldPrice = false
          styleOverride = body_bold_txt
        })
      }
    }

    // buy area
    local notEnoughCurrencyInfo = null
    if (hasBuy.value){
      buyPriceView = mkCurrency({
        currency
        price = price.value
        fullPrice = fullPrice.value
        iconSize = hdpx(20)
      })
      if ((currenciesBalance.value?[currencyId] ?? 0) < price.value)
        notEnoughCurrencyInfo = notEnoughMoneyInfo(price.value, currencyId)
    }

    msgBody.append(mkAllPricesView(barterPriceView, buyPriceView), notEnoughCurrencyInfo,
      mkDiscountInfo(discountState.value))

    return {
      watch = [ price, fullPrice, currenciesBalance, barterInfo, hasBuy, discountState ]
      size = [fsh(80), SIZE_TO_CONTENT]
      margin = [defGap, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = bigPadding
      children = msgBody
    }
  }

  // top-right panel with all relevant currencies
  let topPanel = function(){
    let allResources = []

    if (hasBarter){
      let allBarterCurrencies = curItemCost.keys().map(@(tpl) mkBarterCurrency(tpl))
      allResources.extend(allBarterCurrencies)
    }

    if (hasBuy.value && currencyId in currenciesById.value){
      let buyResource =
        priceWidget(currenciesBalance.value?[currencyId] ?? loc("currency/notAvailable"), currencyId)
          .__update({
            size = [SIZE_TO_CONTENT, flex()]
            gap = hdpx(10)
          })
      allResources.append(buyResource)
    }

    return {
      watch = [hasBuy, currenciesById, currenciesBalance]
      flow = FLOW_HORIZONTAL
      size = [SIZE_TO_CONTENT, flex()]
      gap = hdpx(20)
      children = allResources
    }
  }

  let buttons = Computed(function(){
    let btns = []
    let countVal = countWatched.value
    let priceVal = price.value
    let purchaseCurrency = openShopByCurrencyId?[currencyId]
    if (hasBarter)
      if (barterInfo.value) {
        let [itemTpl = null, priceBarter = 0] = curItemCost.topairs()?[0]
        let buyInfo = getPayItemsData(curItemCost, curCampItems.value, countVal)
        let barterCurrImgs = mkCurrencyImage(getCurrencyPresentation(itemTpl)?.icon)
        let realCurrenciesVal = realCurrencies.value
        btns.append({
          action = function() {
            let deltaOrders = priceBarter * countVal - (realCurrenciesVal?[itemTpl] ?? 0)
            if (deltaOrders > 0)
              notEnoughMsg(itemTpl, deltaOrders)
            else
              barterShopItem(shopItem, buyInfo, countVal)
          }
          customStyle = {
            textCtor = function(textComp, params, handler, group, sf) {
              textComp = btnWithCurrImageComp(
                isSoldier ? loc("btn/enlist") : loc("btn/buy"),
                barterCurrImgs,
                priceBarter,
                sf,
                countVal,
                shopItemPriceInc)
              params = h2_txt
              return textButtonTextCtor(textComp, params, handler, group, sf)
            }
            hotkeys = [[ "^J:Y | Enter | Space", { description = {skip = true}} ]]
          }.__update(primaryFlatButtonStyle)
        })
      }
      else if (referralLink != "") {
        btns.append({
          text = loc("btn/gotoReferralLink")
          action = @() openUrl(referralLink, false, true)
        })
      }
    if (hasBuy.value && !hasOfferExpired.value) {
      let currencyBalance = currenciesBalance.value?[currencyId] ?? 0
      if (currencyBalance >= priceVal * countVal)
        btns.append({
          action = function() {
            if (pOfferGuid == null) {
              buyShopItem(shopItem, currencyId, priceVal, buyCb, countVal)
              sendBigQueryUIEvent("action_buy_currency", null, srcComponent)
            } else {
              buyShopOffer(shopItem, currencyId, priceVal, buyCb, pOfferGuid)
              sendBigQueryUIEvent("action_buy_currency", null, srcComponent)
            }
          }
          customStyle = {
            textCtor = function(textComp, params, handler, group, sf) {
              textComp = btnWithCurrImageComp(
                isSoldier ? loc("btn/enlist") : loc("btn/buy"),
                currencyImage(currency),
                priceVal,
                sf,
                countVal,
                shopItemPriceInc)
              params = h2_txt
              return textButtonTextCtor(textComp, params, handler, group, sf)
            }
          }.__update(purchaseButtonStyle)
        })
      else
        btns.append({
          customStyle = {
            textCtor = function(textComp, params, handler, group, sf) {
              textComp = buyCurrencyText(currency, sf)
              params = h2_txt
              return textButtonTextCtor(textComp, params, handler, group, sf)
            }
          },
          action = function() {
            purchaseCurrency()
            sendBigQueryUIEvent("event_low_currency", null, srcComponent)
          }
        })
    }

    // No gold price and not enough items for barter:
    if (hasBarter && !barterInfo.value && referralLink == "" && !hasBuy.value){
      let rewardIdx = getRewardIdx(curItemCost.keys()?[0])
      if (rewardIdx != null) {
        btns.append({
          text = loc("btn/gotoBattlepass")
          action = @() openBPwindow(rewardIdx)
        })
      }
    }

    btns.append({ text = loc("Cancel") })

    if (viewBtnCb)
      btns.append({
        text = loc("btn/view")
        action = viewBtnCb
        customStyle = viewShopInfoBtnStyle.__update({
          hotkeys = [[ "^J:X", { description = {skip = true}} ]]
        })
      })

    return btns
  })

  if (hasBarter || hasBuy.value){
    let params = {
      text = colorize(MsgMarkedText, title)
      fontStyle = body_txt
      children = msgBoxContent
      topPanel
      buttons
    }
    msgbox.showWithCloseButton(params)
    if (hasBuy.value)
      sendBigQueryUIEvent("open_buy_currency_window", null, srcComponent)
    return
  }

  //In case, when pack in release and dev store is distinguishable
  if (!isProductionCircuit.value && (shopItem?.devStoreId ?? "") != "") {
    buyItemByStoreId(shopItem.devStoreId)
    return
  }

  let { storeId = "" } = shopItem
  if (storeId != "") {
    buyItemByStoreId(storeId)
    return
  }

  // buy on website, no msg window ingame:
  let { purchaseGuid = "", pcLinkGuid = "" } = shopItem
  if (purchaseGuid != "")
    if (buyItemByGuid(pcLinkGuid != "" ? pcLinkGuid : purchaseGuid))
      return

  // no tickets, nor price in gold, simple "not enough tickets" msg box
  msgbox.showMsgbox({ text = loc(costLocId) })
}

return kwarg(buyItem)
