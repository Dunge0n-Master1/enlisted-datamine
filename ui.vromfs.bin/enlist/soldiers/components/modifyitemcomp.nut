from "%enlSqGlob/ui_library.nut" import *

let { fontSub, fontBody, fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, brightAccentColor, defTxtColor, smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { ceil, getRomanNumeral } = require("%sqstd/math.nut")
let faComp = require("%ui/components/faComp.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let mkItemWithMods = require("%enlist/soldiers/mkItemWithMods.nut")
let { TextNormal, TextHover, textMargin
} = require("%ui/components/textButton.style.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { upgradeItem, disposeItem } = require("%enlist/soldiers/model/itemActions.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { diffUpgrades, mkUpgradesStatsComp } = require("itemDetailsPkg.nut")
let { markUpgradesUsed } = require("%enlist/soldiers/model/unseenUpgrades.nut")
let { mkItemCurrency, mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let { primaryFlatButtonStyle } = require("%enlSqGlob/ui/buttonsStyle.nut")
let { mkCounter } = require("%enlist/shop/mkCounter.nut")
let { mkGuidsCountTbl } = require("%enlist/items/itemModify.nut")
let { HighlightFailure } = require("%ui/style/colors.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")
let JB = require("%ui/control/gui_buttons.nut")
let colorize = require("%ui/components/colorize.nut")

let itemSize = [hdpx(315), hdpx(90)]

let mkFaComp = @(text) faComp(text, {
  size = [SIZE_TO_CONTENT, itemSize[1]]
  valign = ALIGN_CENTER
  fontSize = hdpx(30)
  color = defTxtColor
})

let arrowComp = mkFaComp("arrow-circle-right")

let orderViews = @(priceOptions, countWatchedVal) priceOptions
  .filter(@(option) option.canBuyCount >= countWatchedVal)
  .map(@(option) mkItemCurrency({
    currencyTpl = option.orderTpl,
    count = option.ordersInStock,
    textStyle = { color = TextNormal }.__update(fontBody)
  }))

let function mkUpgradeItemInfo(currentItem, upgradedItem, upgradesList,
  priceOptions, countWatched) {

  let itemMaxCount = max(currentItem.count, currentItem?.guids.len() ?? 0)
  let { tier } = upgradedItem
  return @() {
    watch = countWatched
    size = [sw(90), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = fsh(5)
    halign = ALIGN_CENTER
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [
          txt(loc("upgradeItemMsgHeader")).__update({
            hplace = ALIGN_CENTER
          }.__update(fontBody))
          {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_RIGHT
            valign = ALIGN_CENTER
            gap = fsh(2)
            children = orderViews(priceOptions, countWatched.value)
          }
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = 5 * bigPadding
        halign = ALIGN_CENTER
        padding = 5 * bigPadding
        children = [
          mkItemWithMods({
            item = currentItem.__merge({ count = countWatched.value })
            itemSize
            isInteractive = false
          })
          arrowComp
          {
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              mkItemWithMods({
                item = upgradedItem.__merge({ count = countWatched.value })
                itemSize
                isInteractive = false
              })
              upgradesList.len() <= 0 ? null : mkUpgradesStatsComp(upgradesList)
            ]
          }
        ]
      }
      currentItem.itemtype == "vehicle" || itemMaxCount <= 1 ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        gap = bigPadding
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          {
            rendObj = ROBJ_TEXTAREA
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            behavior = Behaviors.TextArea
            text = loc("weapon/upgradesCount", {
              tier = colorize(brightAccentColor, getRomanNumeral(tier))
              count = countWatched.value
              maxCount = itemMaxCount
            })
            color = defTxtColor
          }.__update(fontBody)
          {
            flow = FLOW_HORIZONTAL
            gap = bigPadding * 2
            valign = ALIGN_CENTER
            children = [
              mkCounter(itemMaxCount, countWatched),
              Bordered(loc("btn/upgrade/allItems"), @() countWatched(itemMaxCount))
            ]
          }
        ]
      }
    ]
  }
}

let mkUpgradeItemButtons = function(guids, priceOptions, count) {
  local payData = []
  let hotkeysList = [ [["^J:X"]], [["^J:Y"]] ]
  foreach (option in priceOptions){
    local ordersGuids = getPayItemsData({ [option.orderTpl] = option.orderReq * count },
      curCampItems.value)
    if (ordersGuids != null)
      payData.append(option.__merge({ordersGuids}))
  }

  let buttons = payData.map(@(order, idx) {
    text = ""
    action = @() upgradeItem(mkGuidsCountTbl(guids, count),
      order.ordersGuids, @(_) markUpgradesUsed())
    customStyle = {
      hotkeys = hotkeysList?[idx]
      textCtor = @(_textField, params, handler, group, sf)
        textButtonTextCtor({
          children = {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            margin = textMargin
            children = mkTextRow(loc("btn/upgrade/useOrders"),
              @(t) txt(t).__update({
                color = sf & S_HOVER ? TextHover : TextNormal
              }, fontBody),
              {
                ["{orders}"] = mkItemCurrency({ //warning disable: -forgot-subst
                  currencyTpl = order.orderTpl
                  count = order.orderReq * count
                  textStyle = {
                    color = sf & S_HOVER ? TextHover : TextNormal
                  }.__update(fontBody)
                })
              })
          }
        }, params, handler, group, sf)
    }.__update(primaryFlatButtonStyle)
  }).append({ text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B}" ]] } })

  return payData.len() > 0 ? buttons : [{ text = loc("notEnoughOrders") }]
}

let notEnoughMsg = @(currencyData) msgbox.showMsgbox({
  children = {
    flow = FLOW_VERTICAL
    size = [sw(70), SIZE_TO_CONTENT]
    gap = hdpx(15)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("notEnoughOrders")
      }.__update(fontHeading2)
      {
        flow = FLOW_HORIZONTAL
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("needMoreOrders")
          }.__update(fontHeading2)
          {
            flow = FLOW_HORIZONTAL
            gap = {
              rendObj = ROBJ_TEXT
              text = loc("mainmenu/or")
              vplace = ALIGN_BOTTOM
              padding = bigPadding
            }.__update(fontSub)
            children = currencyData.map(@(curr) {
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              children = [
                {
                  rendObj = ROBJ_TEXT
                  text = curr.orderReq - curr.ordersInStock
                  color = HighlightFailure
                }.__update(fontHeading2)
                mkCurrencyImage(getCurrencyPresentation(curr.orderTpl)?.icon)
              ]
            })
          }
        ]
      }
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        text = loc("dontHaveEnoughOrders")
      }.__update(fontHeading2)
    ]
  }
})

let function openUpgradeItemMsg(currentItem, upgradeData) {
  let {
    guids, armyId, upgradeitem, priceOptions, hasEnoughOrders
  } = upgradeData
  if (guids.len() == 0 && (currentItem?.guid ?? "") == "") {
    msgbox.show({ text = loc("noFreeItemToUpgrade") })
    return
  }

  if (!hasEnoughOrders) {
    notEnoughMsg(priceOptions)
    return
  }

  let countWatched = Watched(1)
  let buttonsWatched = Computed(@() mkUpgradeItemButtons(guids, priceOptions, countWatched.value))

  local upgradedItem = findItemTemplate(allItemTemplates, armyId, upgradeitem)
  if (upgradedItem == null) // it's definitely setup error but it shouldn't break ui
    return

  upgradedItem = currentItem.__merge(upgradedItem, {
    upgradeitem = upgradedItem?.upgradeitem ?? ""
  })

  let upgradesList = diffUpgrades(currentItem)

  msgbox.showMessageWithContent({
    content = mkUpgradeItemInfo(currentItem, upgradedItem, upgradesList,
      priceOptions, countWatched)
    buttons = buttonsWatched
  })
}

let function openDisposeItemMsg(currentItem, disposeData) {
  let {
    armyId, itemBaseTpl, orderTpl, orderCount, isDestructible, isRecyclable, isDisposable,
    guids, batchSize = 1
  } = disposeData
  if (guids == null) {
    msgbox.show({ text = loc("unlinkBeforeDispose") })
    return
  }

  if (isDisposable && guids.len() < batchSize) {
    msgbox.show({
      text = loc("tip/notEnoughItemsDispose", { batchSize, count = orderCount.tointeger() })
    })
    return
  }

  let countWatched = Watched(batchSize)
  let action = @() disposeItem(mkGuidsCountTbl(guids, countWatched.value))
  let buttons = [
    isRecyclable
      ? {
          text = loc("btn/recycle")
          isCurrent = true
          action
          customStyle = {
            hotkeys = [[ "^J:Y | Enter | Space" ]]
          }
        }
      : {
          text = ""
          isCurrent = true
          action
          customStyle = {
            isEnabled = true
            textCtor = @(_textField, params, handler, group, sf)
              textButtonTextCtor({
                children = @(){
                  flow = FLOW_HORIZONTAL
                  valign = ALIGN_CENTER
                  margin = textMargin
                  watch = countWatched
                  children = mkTextRow(loc("btn/acquire"),
                    @(text) {
                      rendObj = ROBJ_TEXT
                      text
                      color = sf & S_HOVER ? TextHover : TextNormal
                    }.__update(fontBody),
                    {
                      ["{orders}"] = mkItemCurrency({ //warning disable: -forgot-subst
                        currencyTpl = orderTpl
                        count = ceil(orderCount * (countWatched.value / batchSize))
                        textStyle = {
                          color = sf & S_HOVER ? TextHover : TextNormal
                        }.__update(fontBody)
                      })
                    }
                  )
                }
              }, params, handler, group, sf)
            hotkeys = [[ "^J:Y | Enter | Space" ]]
          }.__update(primaryFlatButtonStyle)
        }
    { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
  ]

  local children = mkItemWithMods({
    item = currentItem.__merge({ count = 1 })
    itemSize
    isInteractive = false
  })
  if (!isDestructible) {
    local downgradedItem = findItemTemplate(allItemTemplates, armyId, itemBaseTpl)
    downgradedItem = currentItem.__merge(downgradedItem)
    let upgradesList = diffUpgrades(currentItem, 0)
    children = [
      children
      arrowComp
      {
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          mkItemWithMods({
            item = downgradedItem.__merge({ count = 1 })
            itemSize
            isInteractive = false
          })
          upgradesList.len() <= 0 ? null : mkUpgradesStatsComp(upgradesList)
        ]
      }
    ]
  }

  let guidsCount = guids.len()
  let content = {
    size = [hdpx(90), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc(isRecyclable ? "recycleItemMsgHeader"
          : isDestructible ? "disposeItemMsgHeader"
          : "downgradeItemMsgHeader")
        hplace = ALIGN_CENTER
        margin = [0, 0, fsh(5), 0]
      }.__update(fontBody)
      {
        flow = FLOW_HORIZONTAL
        gap = 5 * bigPadding
        valign = ALIGN_TOP
        padding = 5 * bigPadding
        children
      }
      !isDestructible || guidsCount <= 1 ? null : mkCounter(guidsCount, countWatched, batchSize)
    ]
  }

  msgbox.showMessageWithContent({
    content
    buttons
  })
}

return {
  openUpgradeItemMsg
  openDisposeItemMsg
}
