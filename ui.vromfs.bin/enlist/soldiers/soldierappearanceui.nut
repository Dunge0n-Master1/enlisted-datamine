from "%enlSqGlob/ui_library.nut" import *

let textInput = require("%ui/components/textInput.nut")
let obsceneFilter = require("%enlSqGlob/obsceneFilter.nut")
let popupsState = require("%enlSqGlob/ui/popup/popupsState.nut")
let colorize = require("%ui/components/colorize.nut")
let getPayItemsData = require("model/getPayItemsData.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")
let customizationPanelUi = require("customizationPanelUi.nut")

let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { fontXSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { enableExtendedOufit } = require("%enlist/campaigns/campaignConfig.nut")
let { hasLinkByType } = require("%enlSqGlob/ui/metalink.nut")
let { reserveSoldiers } = require("model/chooseSoldiersState.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { clearBorderSymbols, utf8ToUpper } = require("%sqstd/string.nut")
let { curCampItems, curCampItemsCount } = require("model/state.nut")
let { localizeSoldierName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { canUseOrder } = require("components/currencyButton.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let {
  midPadding, defTxtColor, weakTxtColor, titleTxtColor, panelBgColor,
  negativeTxtColor, columnGap, colPart, leftAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let {
  use_callname_change_order, buy_callname_change, use_appearance_change_order,
  buy_appearance_change
} = require("%enlist/meta/clientApi.nut")


const MAX_CHARS = 16
const CALLNAME_ORDER_TPL = "callname_change_order"
const APPEARANCE_ORDER_TPL = "appearance_change_order"


let descTxtStyle = { color = weakTxtColor }.__update(fontXSmall)
let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let spinner = mkSpinner(colPart(0.7))

let tiOptions = {
  margin = 0
  maxChars = MAX_CHARS
  colors = {
    backGroundColor = panelBgColor
    textColor = defTxtColor
  }
  placeholder = utf8ToUpper(loc("customize/writeCallsign"))
}.__update(defTxtStyle)


let changeCallnameGoldCost = Computed(@() configs.value?.gameProfile.changeCallnameGoldCost)
let changeAppearanceGoldCost = Computed(@() configs.value?.gameProfile.changeAppearanceGoldCost)
let callnameChangeInProgress = Watched(false)
let appearanceChangeInProgress = Watched(false)
let isWaitingObsceneFilter = Watched(false)


let function callnameChangeAction(soldier, prevCallname, callname) {
  if (prevCallname == callname)
    return

  let orderTpl = CALLNAME_ORDER_TPL
  let orderReq = 1
  let campItems = curCampItemsCount.value
  if (canUseOrder(orderTpl, orderReq, campItems)) {
    let payData = getPayItemsData({ [orderTpl] = orderReq }, curCampItems.value)
    if (payData != null) {
      callnameChangeInProgress(true)
      use_callname_change_order(soldier.guid, callname, payData, function(_) {
        callnameChangeInProgress(false)
      })
    }
    return
  }

  purchaseMsgBox({
    price = changeCallnameGoldCost
    currencyId = "EnlistedGold"
    description = loc("customize/callnameAcception", { callSign = callname })
    title = loc("customize/callnameChooseForGoldConfirm")
    purchase = function() {
      callnameChangeInProgress(true)
      buy_callname_change(soldier.guid, callname, changeCallnameGoldCost.value, function(_) {
        callnameChangeInProgress(false)
      })
    }
    srcComponent = "buy_change_soldier_callname"
    productView = null
  })
}


let function filterAndSetCallname(callNameToSet, soldier, prevCallname) {
  if (isWaitingObsceneFilter.value)
    return

  isWaitingObsceneFilter(true)
  obsceneFilter(callNameToSet, function(filteredCallName) {
    isWaitingObsceneFilter(false)
    if (filteredCallName != callNameToSet) {
      return popupsState.addPopup({
        id = "prohibited_callname"
        text = loc("prohibitedCallname")
        styleName = "error"
      })
    }
    callnameChangeAction(soldier, prevCallname, filteredCallName)
  })
}


let soldierNameColorized = function(soldier, callname) {
  let { name, surname } = localizeSoldierName(soldier)
  callname = callname != "" ? colorize(titleTxtColor, $"\"{callname}\"") : null
  return " ".join([name, callname, surname], true)
}


let mkCallnamePrice = @(ordersAvailable, priceInGold, btnText, cb, btnStyle = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("mainmenu/buyFor")
        }.__update(defTxtStyle)
        ordersAvailable > 0
          ? mkItemCurrency({
              currencyTpl = CALLNAME_ORDER_TPL
              count = 1
              textStyle = { color = titleTxtColor }
            }).__update({ hplace = ALIGN_RIGHT })
          : mkCurrency({
              currency = enlistedGold
              price = priceInGold
              iconSize = colPart(0.4)
            })

      ]
    }
    Bordered(btnText, cb, { hplace = ALIGN_RIGHT }.__update(btnStyle))
  ]
}


let mkHeader = @(txt, ordersAvailable, tpl) {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(txt)
    }.__update(defTxtStyle)
    mkItemCurrency({
      currencyTpl = tpl
      count = ordersAvailable > 0 ? ordersAvailable : loc("customize/appearanceNotEnoughOrders")
      textStyle = { color = ordersAvailable > 0 ? titleTxtColor : negativeTxtColor }
    }).__update({ hplace = ALIGN_RIGHT })
  ]
}

let function mkCallnameUi(soldierWatch) {
  let ordersAvailable = Computed(@() curCampItemsCount.value?[CALLNAME_ORDER_TPL] ?? 0)
  return function() {
    let soldier = soldierWatch.value
    let prevCallname = soldier?.callname
    let callnameEditWatch = Watched(prevCallname)
    let callnameCleaned = Computed(@() clearBorderSymbols(callnameEditWatch.value))
    let isChanged = Computed(@() callnameCleaned.value != prevCallname)
    return {
      watch = soldierWatch
      key = $"callname_{soldier.guid}"
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      padding = midPadding
      gap = columnGap
      rendObj = ROBJ_SOLID
      color = panelBgColor
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = midPadding
          children = [
            @() {
              watch = ordersAvailable
              size = [flex(), SIZE_TO_CONTENT]
              children = mkHeader(loc("customize/callnameTitle"),
                ordersAvailable.value, CALLNAME_ORDER_TPL)
            }
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              size = [flex(), SIZE_TO_CONTENT]
              text = loc("customize/callnameDescription")
            }.__update(descTxtStyle)
          ]
        }
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = midPadding
          children = [
            textInput(callnameEditWatch, tiOptions.__merge({
              onEscape = @() callnameEditWatch(prevCallname)
              onReturn = @() filterAndSetCallname(callnameCleaned.value, soldier, prevCallname)
            }))
            @() {
              watch = callnameCleaned
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              text = soldierNameColorized(soldier, callnameCleaned.value)
            }.__update(defTxtStyle)
          ]
        }
        @() {
          watch = [ isWaitingObsceneFilter, changeCallnameGoldCost, isChanged,
            callnameChangeInProgress, ordersAvailable ]
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          children = isWaitingObsceneFilter.value ? spinner
            : !isChanged.value || callnameChangeInProgress.value ? null
            : mkCallnamePrice(
                ordersAvailable.value,
                changeCallnameGoldCost.value,
                loc("customize/callnameConfirmBtn"),
                @() filterAndSetCallname(callnameCleaned.value, soldier, prevCallname)
              )
        }
      ]
    }.__update(leftAppearanceAnim(0.2))
  }
}


local function appearanceChangeAction(soldier) {
  local orderTpl = APPEARANCE_ORDER_TPL
  local orderReq = 1
  local campItems = curCampItemsCount.value
  if (canUseOrder(orderTpl, orderReq, campItems)) {
    local payData = getPayItemsData({ [orderTpl] = orderReq }, curCampItems.value)
    if (payData != null){
      appearanceChangeInProgress(true)
      use_appearance_change_order(soldier.guid, payData, function(_) {
        appearanceChangeInProgress(false)
      })
    }
    return
  }

  purchaseMsgBox({
    price = changeAppearanceGoldCost
    currencyId = "EnlistedGold"
    title = loc("customize/appearanceChooseForGoldConfirm")
    description = loc("customize/appearanceAcception")
    purchase = function() {
      appearanceChangeInProgress(true)
      buy_appearance_change(soldier.guid, changeAppearanceGoldCost.value, function(_){
        appearanceChangeInProgress(false)
      })
    }
    srcComponent = "buy_change_soldier_appearance"
    productView = null
  })
}


local function mkAppearanceBlockUi(soldier) {
  if ((soldier?.heroTpl ?? "") != "")
    return null

  let ordersAvailable = Computed(@() curCampItemsCount.value?[APPEARANCE_ORDER_TPL] ?? 0)
  return {
    key = $"appearance_{soldier.guid}"
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = midPadding
    gap = columnGap
    rendObj = ROBJ_SOLID
    color = panelBgColor
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = midPadding
        children = [
          @() {
            watch = ordersAvailable
            size = [flex(), SIZE_TO_CONTENT]
            children = mkHeader(loc("customize/appearanceTitle"),
              ordersAvailable.value, APPEARANCE_ORDER_TPL)
          }
          {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            size = [flex(), SIZE_TO_CONTENT]
            text = loc("customize/appearanceDescription")
          }.__update(descTxtStyle)
        ]
      }
      @() {
        watch = [ordersAvailable, changeAppearanceGoldCost, appearanceChangeInProgress]
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        children = appearanceChangeInProgress.value ? spinner
          : mkCallnamePrice(
              ordersAvailable.value,
              changeAppearanceGoldCost.value,
              loc("customize/appearanceConfirmBtn"),
              @() appearanceChangeAction(soldier),
              { size = [flex(), SIZE_TO_CONTENT] }
            ).__update({
              flow = FLOW_VERTICAL
              gap = midPadding
            })
      }
    ]
  }.__update(leftAppearanceAnim(0.1))
}


return kwarg(@(soldier, _canManage = true) {
  size = flex()
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    function() {
      let { armyId, squadId, guid } = soldier.value
      let hasAppearance = enableExtendedOufit.value
      let isInReserve = reserveSoldiers.value.findvalue(@(v) v.guid == guid) != null
      let isSquadLinked = hasLinkByType(soldier.value, "squad")
      let { isOutfitLocked = false } = squadsCfgById.value?[armyId][squadId]
      return {
        watch = [soldier, enableExtendedOufit, reserveSoldiers, squadsCfgById]
        size = [flex(), SIZE_TO_CONTENT]
        children = isOutfitLocked || isInReserve || !isSquadLinked ? null
          : hasAppearance ? customizationPanelUi
          : mkAppearanceBlockUi(soldier.value)
      }
    }
    mkCallnameUi(soldier)
  ]
})
