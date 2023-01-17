from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { body_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, soldierWndWidth, bigPadding, titleTxtColor, smallPadding,
  blurBgColor, blurBgFillColor, maxContentWidth, slotBaseSize, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let { horGap, emptyGap } = require("%enlist/components/commonComps.nut")
let { curArmyData, curCampItemsCount } = require("model/state.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { isCustomizationWndOpened, itemsPerSlot, saveOutfit, APPEARANCE_ORDER_TPL,
  customizationToApply, totalItemsCost, buyItemsWithCurrency, buyItemsWithTickets,
  PURCHASE_WND_UID, closePurchaseWnd, isPurchasing, itemsToBuy, removeItem,
  removeAndCloseWnd, premiumItemsCount, curSoldierItemsPrice, multipleItemsCost,
  multipleItemsToBuy, isMultiplePurchasing, multipleApplyOutfit
} = require("soldierCustomizationState.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { lookCustomizationBlock, itemBlock, mkPrice
} = require("soldierCustomizationPkg.nut")
let mkHeader = require("%enlist/components/mkHeader.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let { mkMenuScene } = require("%enlist/mainMenu/mkMenuScene.nut")
let mkNameBlock = require("%enlist/components/mkNameBlock.nut")
let { Flat, PrimaryFlat, Purchase, Bordered } = require("%ui/components/textButton.nut")
let { curSoldierInfo } = require("model/squadInfoState.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { addModalWindow } = require("%ui/components/modalWindows.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(70) })
let { multyPurchaseAllowed } = require("%enlist/featureFlags.nut")

let closeButton = closeBtnBase({ onClick = saveOutfit })
let purchaseCloseBtn = closeBtnBase({ onClick = closePurchaseWnd })
let verticalGap = bigPadding * 2
let purchaseWndWidth = min(sw(40), maxContentWidth) - hdpx(75) * 2

let leftBlockHeader = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  text = loc("appearance/title")
  color = defTxtColor
}.__update(body_txt)


let customizationCurrency = @() {
  watch = curCampItemsCount
  children = mkItemCurrency({
    currencyTpl = APPEARANCE_ORDER_TPL
    count = curCampItemsCount.value?[APPEARANCE_ORDER_TPL] ?? 0
    textStyle = { color = defTxtColor, vplace = ALIGN_BOTTOM, fontSize = body_txt.fontSize }
  })
}

let purchaseHeader = {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("appearance/header")
      color = titleTxtColor
      hplace = ALIGN_CENTER
    }.__update(body_txt)
    {
      flow = FLOW_HORIZONTAL
      children = [
        emptyGap
        currenciesWidgetUi
        horGap
        customizationCurrency
        emptyGap
        purchaseCloseBtn
      ]
    }
  ]
}.__update(h2_txt)

let purchaseItemWrapParams = {
  width = purchaseWndWidth
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  vGap = verticalGap
  hGap = verticalGap
}

customizationToApply.subscribe(function(v){
  if (v.len() <= 0)
    closePurchaseWnd()
})

let purchaseContent = @(items = null) function(){
  let removeAction = items == null ? removeItem : removeAndCloseWnd
  local itemsToShow = items == null ? itemsToBuy.value.values() : items
  if (items != null)
    itemsToShow = itemsToShow.reduce(@(res, item) res.indexof(item) == null
      ? res.append(item)//warning disable: -unwanted-modification
      : res, [])

  return {
    watch = itemsToBuy
    size = [purchaseWndWidth, SIZE_TO_CONTENT]
    padding = [verticalGap, 0]
    children = wrap(
      itemsToShow.map(@(item) itemBlock(item, curSoldierItemsPrice.value, items, removeAction)),
      purchaseItemWrapParams)
  }
}

let function purchaseBtnBlock(){
  let allPrices = isMultiplePurchasing.value
    ? multipleItemsCost.value
    : totalItemsCost.value
  let priceList = []
  foreach (key, val in allPrices) {
    if (key == "EnlistedGold")
      priceList.append({
        tmpl = key
        cost = val
      })
    else
      priceList.insert(0, {
        tmpl = key
        cost = val
      })
  }
  let btnsBlock = [
    Flat(loc("BackBtn"), closePurchaseWnd, {
      hotkeys = [[$"^{JB.B} | Esc"]]
    })
  ]

  priceList.each(@(v) btnsBlock.append({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = smallPadding
    children = v.cost <= 0 ? null : [
      mkPrice(v.tmpl, v.cost)
      v.tmpl == "EnlistedGold"
        ? Purchase(loc("mainmenu/purchaseNow"), buyItemsWithCurrency)
        : PrimaryFlat(loc("mainmenu/purchaseNow"), buyItemsWithTickets, {
            isEnabled = (curCampItemsCount.value?[APPEARANCE_ORDER_TPL] ?? 0) >= v.cost
          })
    ]
  }))

  return {
    watch = [isPurchasing, totalItemsCost, isMultiplePurchasing, multipleItemsCost]
    size = [flex(), hdpx(100)]
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children = isPurchasing.value ? spinner : btnsBlock
  }
}


let purchaseWndContet = @(item){
  size = [flex(), SIZE_TO_CONTENT]
  maxWidth = maxContentWidth
  padding = hdpx(75)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = verticalGap
  children = [
    purchaseHeader
    purchaseContent(item)
    purchaseBtnBlock
  ]
}

let purchaseWnd = @(item){
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [flex(), SIZE_TO_CONTENT]
  color = blurBgColor
  fillColor = blurBgFillColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = purchaseWndContet(item)
}

let openPurchaseWnd = @(item = null) addModalWindow({
  key = PURCHASE_WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = flex()
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = purchaseWnd(item)
  onClick = @() null
})

let chooseItemWrapParams = {
  width = slotBaseSize[0]
  vGap = bigPadding
  hGap = bigPadding
  halign = ALIGN_CENTER
}

let chooseItemBlock = @(){
  watch = [itemsPerSlot, premiumItemsCount]
  size = [slotBaseSize[0], flex()]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  flow = FLOW_VERTICAL
  padding = [bigPadding, 0]
  color = blurBgColor
  fillColor = blurBgFillColor
  xmbNode = XmbContainer({
    canFocus = @() true
    scrollSpeed = 5.0
    isViewport = true
  })
  children = makeVertScroll(
      wrap(itemsPerSlot.value.map(@(item)
        itemBlock(item, curSoldierItemsPrice.value, premiumItemsCount.value)),
      chooseItemWrapParams),
    {
      size = [SIZE_TO_CONTENT, flex()]
      styling = thinStyle
    })
}

let multyBuyBtn = @(items) Bordered(loc("appearance/multy_buy_apply"),
  function(){
    isMultiplePurchasing(true)
    openPurchaseWnd(items)
  },
  {
    size = [flex(), commonBtnHeight]
  }
)

let multyApplyBtn = Bordered(loc("appearance/multy_apply"),
  multipleApplyOutfit,
  { size = [flex(), commonBtnHeight] }
)


let function leftCustomisationBlock(){
  let hasMultyPrice = multipleItemsCost.value.len() > 0
  let items = multipleItemsToBuy.value
  return{
    watch = [curSoldierInfo, multipleItemsCost, multyPurchaseAllowed]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = [soldierWndWidth, flex()]
    color = blurBgColor
    fillColor = blurBgFillColor
    flow = FLOW_VERTICAL
    gap = verticalGap
    padding = bigPadding
    children = [
      mkNameBlock(curSoldierInfo)
      leftBlockHeader
      lookCustomizationBlock
      !multyPurchaseAllowed.value ? null
        : hasMultyPrice ? multyBuyBtn(items)
        : multyApplyBtn
    ]
  }
}

let rightBtnBlock = {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  gap = verticalGap
  children = [
    Bordered(loc("BackBtn"), saveOutfit, { margin = 0 })
    @(){
      watch = itemsToBuy
      flow = FLOW_VERTICAL
      gap = verticalGap
      children = [
        {
          rendObj = ROBJ_TEXT
          text = itemsToBuy.value.len() <= 0 ? null
            : loc("appearance/itemsInCart", { count = itemsToBuy.value.len() })
        }.__update(h2_txt)
        Bordered(loc("appearance/purchase"), function(){
          openPurchaseWnd()
          },{
            margin = 0
            isEnabled = itemsToBuy.value.len() > 0
            hotkeys = [["^J:Y", { action = @() openPurchaseWnd() }]]
          })
      ]
    }
  ]
}

let centralBlock = {
  size = flex()
  children = [
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        leftCustomisationBlock
        chooseItemBlock
      ]
    }
    rightBtnBlock
  ]
}

let topBar = @() {
  watch = [curArmyData, curCampItemsCount]
  size = flex()
  maxWidth = maxContentWidth
  children = mkHeader({
    armyId = curArmyData.value?.guid
    textLocId = loc("appearance/choose")
    addToRight = {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        currenciesWidgetUi
        horGap
        customizationCurrency
        emptyGap
      ]
    }
    closeButton
  })
}

let wndContent = mkMenuScene(topBar, centralBlock, {size = [flex(), SIZE_TO_CONTENT]})

let soldierCustomizationScene = {
  size = flex()
  halign = ALIGN_CENTER
  key = "soldierCustomization"
  behavior = Behaviors.MenuCameraControl
  onDetach = @() isCustomizationWndOpened(false)
  children = wndContent
}


isCustomizationWndOpened.subscribe(function(flag){
  if (flag)
    sceneWithCameraAdd(soldierCustomizationScene, "soldiers")
  else
    sceneWithCameraRemove(soldierCustomizationScene)})