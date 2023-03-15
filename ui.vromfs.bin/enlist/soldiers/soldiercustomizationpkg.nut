from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  soldierWndWidth, bigPadding, smallPadding, listCtors, slotBaseSize
} = require("%enlSqGlob/ui/viewConst.nut")
let { soldiersLook } = require("%enlist/meta/servProfile.nut")
let icon3dByGameTemplate = require("%enlSqGlob/ui/icon3dByGameTemplate.nut")
let {
  availableCItem, currentItemPart, curSoldierItemsPrice, oldSoldiersLook,
  itemBlockOnClick, blockOnClick, customizationToApply, customizationItems, itemsInfo
} = require("soldierCustomizationState.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let faComp = require("%ui/components/faComp.nut")
let { appearanceToRender } = require("%enlist/scene/soldier_tools.nut")
let { amountText } = require("%enlist/soldiers/components/itemComp.nut")

let listBgColor = listCtors.bgColor
let listTxtColor = listCtors.txtColor

let blockHeight = hdpx(124)
let blockWidth = (soldierWndWidth - bigPadding * 3) / 2
let currencyIconSize = hdpx(30)

let itemParams = {
  width = blockWidth / 2
  hplace = ALIGN_LEFT
  height = blockHeight - hdpx(10)
}

let selectItemBlockWidth = slotBaseSize[0] - bigPadding * 2
let purchaseItemBlockWidth = blockHeight

let selectingItemParams = {
  width = selectItemBlockWidth / 2
  height = blockHeight
  hplace = ALIGN_LEFT
}

let purchasingItemParams = {
  width = purchaseItemBlockWidth
  height = blockHeight
}

let mkPriceInteractive = @(currencyId, count, group, isSelected) watchElemState(@(sf){
  group
  children = currencyId == "EnlistedGold"
    ? mkCurrency({
        currency = enlistedGold
        price = count
        iconSize = currencyIconSize
        txtStyle = { color = listTxtColor(sf, isSelected) }
      })
    : mkItemCurrency({
        currencyTpl = currencyId
        count
        textStyle = { color = listTxtColor(sf, isSelected), fontSize = body_txt.fontSize }
      })
})

let priceBlock = @(itemPrice, params = {}) function(){
  let priceList = []
  let { isSelected = false, group = null } = params
  foreach (key, val in itemPrice) {
    if (key == "EnlistedGold")
      priceList.insert(0, mkPriceInteractive(key, val.price, group, isSelected))
    else
      priceList.append(mkPriceInteractive(key, val.price, group, isSelected))
  }
  return priceList.len() <= 0 ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = priceList
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
      }
}

local mkCustomizationSlot = @(itemToShow, itemsPrices) watchElemState(function(sf){
  let { slotName, iconAttachments, item, locId, itemTemplate } = itemToShow
  let { armyId = null, guid = null } = curSoldierInfo.value
  let isSelected = slotName == currentItemPart.value
  let group = ElemGroup()
  let itemPrice = itemsPrices?[item] ?? {}
  return armyId == null || guid == null ? null : {
    watch = [soldiersLook, currentItemPart, curSoldierInfo]
    rendObj = ROBJ_SOLID
    size = [blockWidth, blockHeight]
    margin = [0, bigPadding]
    onClick = @() blockOnClick(slotName)
    halign = ALIGN_RIGHT
    behavior = Behaviors.Button
    color = listBgColor(sf, isSelected)
    group
    children = [
      {
        rendObj = ROBJ_TEXT
        padding = smallPadding
        color = listTxtColor(sf, isSelected)
        text = loc(locId)
      }
      icon3dByGameTemplate(itemTemplate, itemParams.__merge({
        genOverride = { iconAttachments }
        shading = "same"
      }))
      currentItemPart.value == ""
        ? null
        : priceBlock(itemPrice, {
            vplace = ALIGN_BOTTOM
            padding = [smallPadding, 0]
            group
            isSelected
          })
    ]}
})

let function mkPrice(currencyId, count){
  if (currencyId == "EnlistedGold")
    return mkCurrency({
      currency = enlistedGold
      price = count
      iconSize = currencyIconSize
    })

  return mkItemCurrency({
    currencyTpl = currencyId
    count
    textStyle = { fontSize = body_txt.fontSize }
  })
}


let removeBtn = @(item, removeAction) watchElemState(@(sf){
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.Button
  padding = smallPadding
  valign = ALIGN_CENTER
  onClick = @() removeAction(item)
  rendObj =  ROBJ_SOLID
  color = listBgColor(sf)
  children = [
    faComp("close", {
      fontSize = hdpx(12)
      color = listTxtColor(sf)
    })
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_RIGHT
      color = listTxtColor(sf)
      text = loc("remove")
    }
  ]
})

let defaultItemTitle = @(sf, isSelected){
  rendObj = ROBJ_TEXT
  text = loc("appearance/default_item")
  hplace = ALIGN_RIGHT
  color = listTxtColor(sf, isSelected)
}


let function selectingItemBlock(item, itemTemplate, guid, isSelected,
  iconAttachments, premiumItemsCount, itemPrice
){
  let group = ElemGroup()
  let isDefaultItem = soldiersLook.value[guid].items.findvalue(@(val) val == item) != null
  let rightTopInfo = @(sf, isSelected) isDefaultItem
    ? defaultItemTitle(sf, isSelected)
      : item in premiumItemsCount && premiumItemsCount[item] > 1
    ? amountText(premiumItemsCount[item], sf, isSelected)
      : null

  return watchElemState(@(sf){
    watch = soldiersLook
    size = [selectItemBlockWidth, blockHeight]
    rendObj = ROBJ_SOLID
    padding = bigPadding
    xmbNode = XmbNode()
    behavior = Behaviors.Button
    halign = ALIGN_RIGHT
    color = listBgColor(sf, isSelected)
    onClick = @() itemBlockOnClick(item)
    group
    onHover = function(hovered){
      let currentSlot = currentItemPart.value
      local res = appearanceToRender.value ?? {}
      let itemToShow = hovered
        ? item
        : customizationToApply.value?[currentSlot] ?? oldSoldiersLook.value?[currentSlot]
      if (itemToShow == null)
        return
      res = res.__merge({ [currentSlot] = itemToShow })
      appearanceToRender(res)
    }

    children = [
      icon3dByGameTemplate(itemTemplate, selectingItemParams.__merge({
        genOverride = { iconAttachments }
        shading = "same"
      }))
      rightTopInfo(sf, isSelected)
      priceBlock(itemPrice, {
        vplace = ALIGN_BOTTOM
        isSelected
        group
      })
    ]
  })
}

let purchasingItemBlock = @(item, itemTemplate, premiumItemsCount, removeAction,
  iconAttachments, itemPrice) watchElemState(@(sf){
    flow = FLOW_VERTICAL
    gap = smallPadding
    halign = ALIGN_CENTER
    children = [{
      size = [blockHeight, blockHeight]
      rendObj = ROBJ_SOLID
      color = listBgColor(sf)
      children = [
        (premiumItemsCount ?? []).len() <= 1 ? null : amountText(premiumItemsCount.len(), sf, false)
        icon3dByGameTemplate(itemTemplate, purchasingItemParams.__merge({
          genOverride = { iconAttachments }
          shading = "same"
        }))
      ]
    }
      priceBlock(itemPrice)
      removeBtn(item, removeAction)
    ]
  })


let itemBlock = @(item, itemsPrices, premiumItemsCount = [], removeAction = null) function(){
  let { guid } = curSoldierInfo.value
  let { gametemplate, iconAttachments = [] } = itemsInfo.value[item]
  let isSelected = Computed(@() removeAction == null && item in customizationItems.value)
  let itemPrice = itemsPrices?[item] ?? {}
  return {
    watch = [curSoldierInfo, isSelected, itemsInfo]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      removeAction == null
        ? selectingItemBlock(item, gametemplate, guid, isSelected.value,
            iconAttachments, premiumItemsCount, itemPrice)
        : purchasingItemBlock(item, gametemplate, premiumItemsCount, removeAction,
            iconAttachments, itemPrice)
    ]}
}

let lookWrapParams = {
  width = soldierWndWidth
  vGap = bigPadding
}


let lookCustomizationBlock = @(){
  watch = [availableCItem, currentItemPart, curSoldierItemsPrice]
  size = flex()
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [wrap(availableCItem.value.map(@(item)
    mkCustomizationSlot(item, curSoldierItemsPrice.value)), lookWrapParams)
    currentItemPart.value != "tunic" ? null : {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = loc("appearance/attachments_override")
      halign = ALIGN_CENTER
    }.__update(body_txt)
  ]
}


return {
  lookCustomizationBlock
  itemBlock
  currencyIconSize
  mkPrice
}