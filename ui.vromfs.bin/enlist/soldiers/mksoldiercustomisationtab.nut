from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let textInput = require("%ui/components/textInput.nut")
let { defTxtColor, commonBtnHeight } = require("%enlSqGlob/ui/viewConst.nut")
let { curCampItems, curCampItemsCount } = require("model/state.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let getPayItemsData = require("model/getPayItemsData.nut")
let {
  use_callname_change_order, buy_callname_change,
  use_appearance_change_order, buy_appearance_change
} = require("%enlist/meta/clientApi.nut")
let { clearBorderSymbols } = require("%sqstd/string.nut")
let colorize = require("%ui/components/colorize.nut")
let { localizeSoldierName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  canUseOrder, mkCurrencyButton
} = require("%enlist/soldiers/components/currencyButton.nut")
let obsceneFilter = require("%enlSqGlob/obsceneFilter.nut")
let spinner = require("%ui/components/spinner.nut")({ height = commonBtnHeight })
let popupsState = require("%enlist/popup/popupsState.nut")
let { lookCustomizationBlock } = require("soldierCustomizationPkg.nut")
let { enableExtendedOufit } = require("%enlist/campaigns/campaignConfig.nut")
let { reserveSoldiers } = require("model/chooseSoldiersState.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { hasLinkByType } = require("%enlSqGlob/ui/metalink.nut")

const MAX_CHARS = 16
const CALLNAME_ORDER_TPL = "callname_change_order"
const APPEARANCE_ORDER_TPL = "appearance_change_order"

let changeCallnameGoldCost = Computed(@() configs.value?.gameProfile.changeCallnameGoldCost)
let changeAppearanceGoldCost = Computed(@() configs.value?.gameProfile.changeAppearanceGoldCost)
let callnameChangeInProgress = Watched(false)
let appearanceChangeInProgress = Watched(false)
let isWaitingObsceneFilter = Watched(false)

let tiOptions = {
  margin = [hdpx(8),0,0,0]
  padding = 0
  textmargin = hdpx(5)
  maxChars = MAX_CHARS
  colors = { backGroundColor = Color(0, 0, 0, 255) }
  placeholder = loc("customize/writeCallsign")
}.__update(body_txt)

let function callnameChangeAction(soldier, prevCallname, callname) {
  if (prevCallname == callname)
    return

  let orderTpl = CALLNAME_ORDER_TPL
  let orderReq = 1
  let campItems = curCampItemsCount.value
  if (canUseOrder(orderTpl, orderReq, campItems)) {
    let payData = getPayItemsData({ [orderTpl] = orderReq }, curCampItems.value)
    if (payData != null){
      callnameChangeInProgress(true)
      use_callname_change_order(soldier.guid, callname, payData, function(_){
        callnameChangeInProgress(false)
      })
    }
    return
  }

  purchaseMsgBox({
    price = changeCallnameGoldCost
    currencyId = "EnlistedGold"
    description = loc("customize/callnameAcception", {callSign = callname})
    title = loc("customize/callnameChooseForGoldConfirm")
    purchase = function() {
      callnameChangeInProgress(true)
      buy_callname_change(soldier.guid, callname, changeCallnameGoldCost.value, function(_){
        callnameChangeInProgress(false)
      })
    }
    srcComponent = "buy_change_soldier_callname"
    productView = null
  })
}

let stdText = @(text){
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  color = defTxtColor
  text
}.__update(sub_txt)

let soldierNameColorized = function(soldier, callname){
  let { name, surname } = localizeSoldierName(soldier)
  callname = callname != "" ? colorize(0xFFFFFF, $"\"{callname}\"") : null
  return " ".join([loc(name), callname, loc(surname)], true)
}

let function filterAndSetCallname(callNameToSet, soldier, prevCallname){
  if (isWaitingObsceneFilter.value)
    return
  isWaitingObsceneFilter(true)
  obsceneFilter(callNameToSet, function(filteredCallName){
    isWaitingObsceneFilter(false)
    if (filteredCallName != callNameToSet){
      return popupsState.addPopup({
        id = "prohibited_callname"
        text = loc("prohibitedCallname")
        styleName = "error"
      })
    }
    callnameChangeAction(soldier, prevCallname, filteredCallName)
  })
}

let function mkCallnameBlock(soldier){
  let ordersAvailable = curCampItemsCount.value?[CALLNAME_ORDER_TPL] ?? 0
  let callnameEditWatch = Watched(soldier?.callname)
  let callnameCleaned = Computed(@() clearBorderSymbols(callnameEditWatch.value))
  let prevCallname = soldier?.callname
  let isChanged = Computed(@() callnameCleaned.value != prevCallname)
  return @() {
    watch = [
      curCampItemsCount, changeCallnameGoldCost, isChanged,
      callnameChangeInProgress, isWaitingObsceneFilter
    ]
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = hdpx(8)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("customize/callnameTitle")
      }.__update(sub_txt)
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        color = defTxtColor
        text = loc("customize/callnameDescription")
      }.__update(sub_txt)
      textInput(callnameEditWatch,
        tiOptions.__merge({
          onEscape = @() callnameEditWatch(prevCallname)
          onReturn = @() filterAndSetCallname(callnameCleaned.value, soldier, prevCallname)
        }))
      @() {
        watch = callnameCleaned
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = defTxtColor
        text = soldierNameColorized(soldier, callnameCleaned.value)
      }
      isWaitingObsceneFilter.value
        ? {
            size =[flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            children = spinner
          }
        : {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            vplace = ALIGN_BOTTOM
            children = [
              {
                size = [flex(), SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                hplace = ALIGN_CENTER
                valign = ALIGN_BOTTOM
                gap = hdpx(5)
                children = [
                  stdText(loc( ordersAvailable == 0
                    ? "shop/noOrdersAvailable"
                    : "shop/youHave"
                  ))
                  mkItemCurrency({
                    currencyTpl = CALLNAME_ORDER_TPL
                    count = ordersAvailable > 0 ? ordersAvailable : null
                    textStyle = { color = defTxtColor, vplace = ALIGN_BOTTOM }
                  })
                ]
              }
              mkCurrencyButton({
                text = loc("customize/callnameConfirmBtn")
                cb = @() filterAndSetCallname(callnameCleaned.value, soldier, prevCallname)
                orderTpl = CALLNAME_ORDER_TPL
                orderCount = 1
                cost = changeCallnameGoldCost.value
                campItems = curCampItemsCount.value
                isEnabled = isChanged.value && !callnameChangeInProgress.value
              })
            ]
          }
    ]
  }
}

local function appearanceChangeAction(soldier){
  local orderTpl = APPEARANCE_ORDER_TPL
  local orderReq = 1
  local campItems = curCampItemsCount.value
  if (canUseOrder(orderTpl, orderReq, campItems)) {
    local payData = getPayItemsData({ [orderTpl] = orderReq }, curCampItems.value)
    if (payData != null){
      appearanceChangeInProgress(true)
      use_appearance_change_order(soldier.guid, payData, function(_){
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

local function mkAppearanceBlock(soldier){
  if ((soldier?.heroTpl ?? "") != "")
    return null

  local ordersAvailable = curCampItemsCount.value?[APPEARANCE_ORDER_TPL] ?? 0
  return @() {
    watch = [
      curCampItemsCount, changeAppearanceGoldCost, appearanceChangeInProgress
    ]
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = hdpx(8)
    children = [
      {
        rendObj = ROBJ_BOX
        borderColor = 0x404040
        borderWidth = hdpx(1)
        size = [flex(), hdpx(1)]
        margin = [hdpx(10), 0, 0, 0]
      }
      {
        rendObj = ROBJ_TEXT
        text = loc("customize/appearanceTitle")
        hplace = ALIGN_CENTER
      }.__update(sub_txt)
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        color = defTxtColor
        text = loc("customize/appearanceDescription")
      }.__update(sub_txt)
      {
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        gap = hdpx(5)
        children = [
          stdText(loc( ordersAvailable == 0
            ? "shop/noOrdersAvailable"
            : "shop/youHave"
          ))
          mkItemCurrency({
            currencyTpl = APPEARANCE_ORDER_TPL
            count = ordersAvailable > 0 ? ordersAvailable : null
            textStyle = { color = defTxtColor, vplace = ALIGN_BOTTOM }
          })
        ]
      }
      mkCurrencyButton({
        text = loc("customize/appearanceConfirmBtn")
        cb = @() appearanceChangeAction(soldier)
        orderTpl = APPEARANCE_ORDER_TPL
        orderCount = 1
        cost = changeAppearanceGoldCost.value
        campItems = curCampItemsCount.value
        isEnabled =  !appearanceChangeInProgress.value
      })
    ]
  }
}



let customizationTab = @(soldier) function(){
  let { armyId, squadId } = soldier
  let canChangeAppearance = enableExtendedOufit.value
  let isPlacedInReserve = !hasLinkByType(soldier, "squad")
    || reserveSoldiers.value.findvalue(@(v) v.guid == soldier.guid) != null
  let { isOutfitLocked = false } = squadsCfgById.value?[armyId][squadId]

  return {
    watch = [enableExtendedOufit, reserveSoldiers, squadsCfgById]
    size = flex()
    gap = hdpx(10)
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      isOutfitLocked || isPlacedInReserve? null
        : canChangeAppearance ? lookCustomizationBlock
        : mkAppearanceBlock(soldier)
      mkCallnameBlock(soldier)
    ]
  }
}

return kwarg(customizationTab)