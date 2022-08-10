from "%enlSqGlob/ui_library.nut" import *
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, bigPadding, unitSize, warningColor, smallOffset, listCtors, blurBgColor,
  commonBtnHeight, rarityColors
} = require("%enlSqGlob/ui/viewConst.nut")
let { bgColor, txtColor } = listCtors
let { WindowBd } = require("%ui/style/colors.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let faComp = require("%ui/components/faComp.nut")
let { use_transfer_item_order } = require("%enlist/meta/clientApi.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { Flat, PrimaryFlat } = require("%ui/components/textButton.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { curCampItems, curCampItemsCount } = require("%enlist/soldiers/model/state.nut")
let mkItemWithMods = require("%enlist/soldiers/mkItemWithMods.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(70) })
let JB = require("%ui/control/gui_buttons.nut")

const WND_UID = "item_transfer_msg"
let costHeight = hdpx(60)

let transferStatus = Watched(null)
let close = @() removeModalWindow(WND_UID)

let textArea = @(text, style = body_txt) {
  size = [hdpx(800), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = defTxtColor
  text
}.__update(style)

let function useTransferItemOrder(itemGuid, armyId, costCfg, variant) {
  let reqOrders = { [costCfg.orderTpl] = costCfg.orderRequire }
  let payData = getPayItemsData(reqOrders, curCampItems.value)
  if (payData == null) {
    transferStatus({ errorTxt = "notEnoughOrders", isSuccess = false, variant })
    return
  }

  transferStatus({ isInProgress = true, variant })
  use_transfer_item_order(itemGuid, armyId, payData,
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
    let tColor = txtColor(sf, isSelected.value)
    return {
      watch = isSelected
      rendObj = ROBJ_SOLID
      size = [armySlotWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      padding = bigPadding
      gap = bigPadding
      valign = ALIGN_CENTER
      color = bgColor(sf, isSelected.value)
      behavior = Behaviors.Button
      onClick
      children = [
        mkArmyIcon(armyId, armyIconSize, { margin = 0 })
        {
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            {
              flow = FLOW_VERTICAL
              children = [
                txt({ text = armyName, color = tColor }.__update(sub_txt))
                txt({ text = campaignName, color = tColor }.__update(sub_txt))
              ]
            }
            isTransferAllowed ? null
              : mkFaComp("lock").__update({
                  size = SIZE_TO_CONTENT
                  hplace = ALIGN_RIGHT
                  color = tColor
                  fontSize = hdpx(18)
                })
          ]
        }
      ]
    }
  })
}

let horLinesBorder = {
  rendObj = ROBJ_BOX
  padding = [hdpx(1), 0]
  borderWidth = [hdpx(1), 0]
  fillColor = 0
  borderColor = defTxtColor
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

let mkTransferArmies = @(variants, selectIdx) horLinesBorder.__merge({
  flow = FLOW_HORIZONTAL
  children = wrap(variants.map(@(variant, idx) mkArmy(variant, Computed(@() idx == selectIdx.value), @() selectIdx(idx))),
    { width = armySlotWidth * min(variants.len(), 3) })
})

let mkCurArmy = @(selVariant) @() horLinesBorder.__merge({
  watch = selVariant
  children = selVariant.value != null ? mkArmy(selVariant.value, Watched(true)) : null
})

let costNotEnough = @(currencyTpl, count) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    txt({
      text = loc("notEnoughOrders")
      hplace = ALIGN_CENTER
      color = warningColor
    }.__update(sub_txt))
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
    }.__update(sub_txt))
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
      }.__update(sub_txt))
    : missOrders.value > 0 ? costNotEnough(costCfg.value.orderTpl, missOrders.value)
    : costAvailable(costCfg.value.orderTpl, costCfg.value.orderRequire)
}

let exitHotkeys = { hotkeys = [["^Esc | {0}".subst(JB.B), { description = { skip = true }}]] }

let mkButtons = @(item, selVariant, costCfg, missOrders) function() {
  local children = []
  if (transferStatus.value?.isInProgress)
    children = spinner
  else if (transferStatus.value != null)
    children = Flat(loc("Ok"), close, exitHotkeys)
  else {
    let { isTransferAllowed = false, armyId = "" } = selVariant.value
    let cost = costCfg.value
    if (isTransferAllowed && missOrders.value <= 0)
      children.append(PrimaryFlat(loc("btn/moveItemToArmy"),
        @() useTransferItemOrder(item.guid, armyId, cost, selVariant.value)))
    children.append(Flat(loc("Cancel"), close, exitHotkeys))
  }
  return {
    watch = [selVariant, costCfg, missOrders, transferStatus]
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
  let costCfg = Computed(function() {
    let { tier = 0 } = allItemTemplates.value?[selVariant.value?.armyId][item.basetpl]
    return requiredOrders[min(tier, requiredOrders.len() - 1)]
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
      {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        children = [
          textArea(loc("transferReqArmyLevel/desc"), sub_txt)
          @() {
            watch = [curCampItemsCount, costCfg]
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            hplace = ALIGN_RIGHT
            valign = ALIGN_CENTER
            children = [
              txt(loc("shop/youHave"))
              mkItemCurrency({
                currencyTpl = costCfg.value.orderTpl
                count = curCampItemsCount.value?[costCfg.value.orderTpl] ?? 0
              })
            ]
          }
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
      mkButtons(item, selVariant, costCfg, missOrders)
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