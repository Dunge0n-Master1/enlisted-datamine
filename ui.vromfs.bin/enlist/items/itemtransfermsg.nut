from "%enlSqGlob/ui_library.nut" import *
let { fontSub, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, bigPadding, unitSize, warningColor, smallOffset, blurBgColor,
  commonBtnHeight, rarityColors
} = require("%enlSqGlob/ui/viewConst.nut")
let { hoverSlotBgColor, panelBgColor, accentColor, selectedPanelBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { WindowBd } = require("%ui/style/colors.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let faComp = require("%ui/components/faComp.nut")
let { use_transfer_item_order_count } = require("%enlist/meta/clientApi.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { Flat, PrimaryFlat, Bordered } = require("%ui/components/textButton.nut")
let { setTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { curCampItems, curCampItemsCount } = require("%enlist/soldiers/model/state.nut")
let mkItemWithMods = require("%enlist/soldiers/mkItemWithMods.nut")
let { mkArmyIcon, mkArmySimpleIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let { mkGuidsCountTbl } = require("%enlist/items/itemModify.nut")
let { mkCounter } = require("%enlist/shop/mkCounter.nut")
let spinner = require("%ui/components/spinner.nut")
let JB = require("%ui/control/gui_buttons.nut")

const WND_UID = "item_transfer_msg"
let costHeight = hdpx(60)
let colorGray = Color(30, 44, 52)

let transferStatus = Watched(null)
let close = @() removeModalWindow(WND_UID)
let waitingSpinner = spinner(hdpx(35))

let textArea = @(text, style = fontBody) {
  size = [hdpx(800), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = defTxtColor
  text
}.__update(style)

let function useTransferItemOrder(itemGuidsTbl, armyId, costCfg, variant) {
  let reqOrders = { [costCfg.orderTpl] = costCfg.orderRequire }
  let payData = getPayItemsData(reqOrders, curCampItems.value)
  if (payData == null) {
    transferStatus({ errorTxt = "notEnoughOrders", isSuccess = false, variant })
    return
  }

  transferStatus({ isInProgress = true, variant })
  use_transfer_item_order_count(itemGuidsTbl, armyId, payData,
    @(res) transferStatus({ errorTxt = res?.error, isSuccess = "error" not in res, variant }))
}

let mkFaComp = @(text) faComp(text, {
  size = [SIZE_TO_CONTENT, 2.0 * unitSize]
  valign = ALIGN_CENTER
  fontSize = hdpx(30)
  color = defTxtColor
})

let mkTransferItemInfo = @(item) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    mkItemWithMods({
      item = item.__merge({ count = 1 })
      itemSize = [7.0 * unitSize, 2.0 * unitSize]
      isInteractive = false
    })
    mkFaComp("arrow-circle-down")
  ]
}

let armyIconSize = hdpxi(44)
let armySlotWidth = fsh(25)

let function mkArmy(variant, isSelected, onClick = null) {
  let { armyId, isTransferAllowed, armyName, campaignName } = variant
  return watchElemState(function(sf) {
    let color = sf & S_HOVER ? colorGray : hoverSlotBgColor
    let bgColor = sf & S_HOVER ? hoverSlotBgColor
      : isSelected.value ? selectedPanelBgColor
      : panelBgColor
    let icon = isSelected.value
      ? mkArmyIcon(armyId, armyIconSize, {margin = 0})
      : mkArmySimpleIcon(armyId, armyIconSize, {
          color
          margin = 0
        })
    return {
      watch = isSelected
      rendObj = ROBJ_BOX
      size = [armySlotWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      padding = bigPadding
      gap = bigPadding
      valign = ALIGN_CENTER
      fillColor = bgColor
      borderWidth = isSelected.value ? [0, 0, hdpx(2), 0] : 0
      borderColor = accentColor
      behavior = Behaviors.Button
      onClick
      children = [
        icon
        {
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            {
              flow = FLOW_VERTICAL
              children = [
                txt({ text = armyName, color }.__update(fontSub))
                txt({ text = campaignName, color }.__update(fontSub))
              ]
            }
            isTransferAllowed ? null
              : mkFaComp("lock").__update({
                  size = SIZE_TO_CONTENT
                  hplace = ALIGN_RIGHT
                  color
                  fontSize = hdpx(18)
                })
          ]
        }
      ]
    }
  })
}

let mkTierChangeInfo = @(item, selVariant) function() {
  let res = { watch = selVariant }
  let variant = selVariant.value ?? {}
  let curTier = item?.tier ?? 1
  let newTier = variant?.tier ?? 1
  if (curTier == newTier)
    return res

  let receivedItem = item.__merge(variant, { count = 1 })
  return res.__update({
    margin = [bigPadding, 0, 0, 0]
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = [
      txt({
        text = loc("itemTransferTierChangeAlert")
        color = rarityColors[1]
      })
      mkItemWithMods({
        item = receivedItem
        itemSize = [7.0 * unitSize, 2.0 * unitSize]
        isInteractive = false
      })
    ]
  })
}

let mkTransferArmies = @(variants, selectIdx) {
  flow = FLOW_HORIZONTAL
  children = wrap(variants.map(@(variant, idx) mkArmy(variant, Computed(@() idx == selectIdx.value), @() selectIdx(idx))),
    { width = armySlotWidth * min(variants.len(), 3) })
}

let mkCurArmy = @(selVariant) @() {
  watch = selVariant
  children = selVariant.value != null ? mkArmy(selVariant.value, Watched(true)) : null
}

let costNotEnough = @(currencyTpl, count) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    txt({
      text = loc("needMoreOrders")
      hplace = ALIGN_CENTER
      color = warningColor
    }.__update(fontSub))
    mkItemCurrency({ currencyTpl, count })
  ]
}

let costAvailable = @(currencyTpl, count) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    txt({
      text = loc("shop/willCostYou")
      hplace = ALIGN_CENTER
      color = defTxtColor
    }.__update(fontSub))
    mkItemCurrency({ currencyTpl, count })
  ]
}

let mkTransferCost = @(selVariant, missOrders, costCfg) @() {
  watch = [selVariant, missOrders, costCfg]
  size = [SIZE_TO_CONTENT, costHeight]
  margin = fsh(2)
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = selVariant.value == null ? null
    : selVariant.value?.transferError != null ? txt({
        text = selVariant.value.transferError
        color = warningColor
        hplace = ALIGN_CENTER
      }.__update(fontSub))
    : missOrders.value > 0 ? costNotEnough(costCfg.value.orderTpl, missOrders.value)
    : costAvailable(costCfg.value.orderTpl, costCfg.value.orderRequire)
}

let exitHotkeys = { hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]] }

let mkButtons = @(item, countWatched, selVariant, costCfg, missOrders) function() {
  local children = []
  if (transferStatus.value?.isInProgress)
    children = waitingSpinner
  else if (transferStatus.value != null)
    children = Flat(loc("Ok"), close, exitHotkeys)
  else {
    let { isTransferAllowed = false, armyId = "" } = selVariant.value
    let itemData = mkGuidsCountTbl(item?.guids ?? [item.guid], countWatched.value)
    if (isTransferAllowed && missOrders.value <= 0)
      children.append(PrimaryFlat(loc("btn/moveItemToArmy"),
        @() useTransferItemOrder(itemData, armyId, costCfg.value, selVariant.value)))
    children.append(Flat(loc("Cancel"), close, exitHotkeys))
  }
  return {
    watch = [selVariant, costCfg, missOrders, transferStatus, countWatched]
    size = [SIZE_TO_CONTENT, commonBtnHeight]
    flow = FLOW_HORIZONTAL
    children
  }
}

let function transferResult() {
  let { isSuccess = false, errorTxt = null } = transferStatus.value
  return {
    watch = transferStatus
    minHeight = costHeight
    valign = ALIGN_CENTER
    children = isSuccess ? textArea(loc("msg/transferSuccess"))
      : errorTxt != null ? textArea(loc(errorTxt))
      : null
  }
}

let function mkTransferContent(item, moveVariants, requiredOrders) {
  let selectIdx = Watched(0)
  let selVariant = Computed(@() transferStatus.value?.variant ?? moveVariants.value?[selectIdx.value])

  let countWatched = Watched(1)
  let itemMaxCount = max(item.count, item?.guids.len() ?? 0)

  let costCfg = Computed(function() {
    let { tier = 0 } = allItemTemplates.value?[selVariant.value?.armyId][item.basetpl]
    local cost = clone requiredOrders[min(tier, requiredOrders.len() - 1)]
    cost.orderRequire *= countWatched.value
    return cost
  })

  let missOrders = Computed(@()
    costCfg.value.orderRequire - (curCampItemsCount.value?[costCfg.value.orderTpl] ?? 0))

  return @() {
    watch = [moveVariants, transferStatus]
    size = [fsh(100), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = smallOffset
    children = [
      textArea(loc("transferReqArmyLevel/desc"), fontSub)
      @() {
        watch = [curCampItemsCount, costCfg]
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        hplace = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          txt(loc("shop/youHave"))
          mkItemCurrency({
            currencyTpl = costCfg.value.orderTpl
            count = curCampItemsCount.value?[costCfg.value.orderTpl] ?? 0
          })
        ]
      }
      {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = [
          mkTransferItemInfo(item)
          transferStatus.value == null ? mkTransferArmies(moveVariants.value, selectIdx)
            : mkCurArmy(selVariant)
          mkTierChangeInfo(item, selVariant)

          transferStatus.value == null ? mkTransferCost(selVariant, missOrders, costCfg)
            : transferResult
        ]
      }
      transferStatus.value != null ? null : {
        flow = FLOW_HORIZONTAL
        gap = bigPadding * 2
        children = [
          mkCounter(itemMaxCount, countWatched)
          Bordered(loc("btn/upgrade/allItems"), @() countWatched(itemMaxCount),
            {
              margin = 0
              size = [ SIZE_TO_CONTENT, hdpx(40)]
              cursor = normalTooltipTop
              onHover = function(on) {
                setTooltip(on ? loc("btn/moveItemToArmy/allItemsTooltip") : null)
              }
            })
        ]
      }
      mkButtons(item, countWatched, selVariant, costCfg, missOrders)
    ]
  }
}

let itemTransferMsg = @(item, moveVariants, requiredOrders) addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  size = flex()
  valign = ALIGN_CENTER
  onClick = @() null
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    halign = ALIGN_CENTER
    fillColor = Color(0, 0, 0, 120)
    borderColor = WindowBd
    borderWidth = [hdpx(1), 0, hdpx(1), 0]
    padding = hdpx(20)
    onAttach = @() transferStatus(null)
    onDetach = @() transferStatus(null)
    children = mkTransferContent(item, moveVariants, requiredOrders)
  }
})

return itemTransferMsg