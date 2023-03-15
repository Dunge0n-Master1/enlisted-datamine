from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, body_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let mkItemWithMods = require("%enlist/soldiers/mkItemWithMods.nut")
let { TextNormal, TextHover, textMargin
} = require("%ui/components/textButton.style.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { setTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { upgradeItem, disposeItem } = require("%enlist/soldiers/model/itemActions.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { defTxtColor, bigPadding, unitSize, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { diffUpgrades } = require("itemDetailsPkg.nut")
let { markUpgradesUsed } = require("%enlist/soldiers/model/unseenUpgrades.nut")
let { mkItemCurrency, mkCurrencyImage } = require("%enlist/shop/currencyComp.nut")
let { primaryFlatButtonStyle } = require("%enlSqGlob/ui/buttonsStyle.nut")
let { mkCounter } = require("%enlist/shop/mkCounter.nut")
let { mkGuidsCountTbl } = require("%enlist/items/itemModify.nut")
let { HighlightFailure } = require("%ui/style/colors.nut")
let { getCurrencyPresentation } = require("%enlist/shop/currencyPresentation.nut")

let mkFaComp = @(text) faComp(text, {
  size = [SIZE_TO_CONTENT, 2.0 * unitSize]
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
    textStyle = { color = TextNormal }.__update(body_txt)
  }))

let function mkUpgradeItemInfo(currentItem, upgradedItem, upgradesList,
  priceOptions, countWatched) {

  let itemMaxCount = max(currentItem.count, currentItem?.guids.len() ?? 0)

  return {
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
          }.__update(body_txt))
          @() {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_RIGHT
            valign = ALIGN_CENTER
            gap = fsh(2)
            watch = countWatched
            children = orderViews(priceOptions, countWatched.value)
          }
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        gap = 5 * bigPadding
        valign = ALIGN_TOP
        padding = 5 * bigPadding
        children = [
          mkItemWithMods({
            item = currentItem.__merge({ count = 1 })
            itemSize = [7.0 * unitSize, 2.0 * unitSize]
            isInteractive = false
          })
          arrowComp
          {
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              mkItemWithMods({
                item = upgradedItem.__merge({ count = 1 })
                itemSize = [7.0 * unitSize, 2.0 * unitSize]
                isInteractive = false
              })
              upgradesList.len() <= 0 ? null : {
                rendObj = ROBJ_TEXTAREA
                size = [flex(), SIZE_TO_CONTENT]
                text = "\n".join(upgradesList)
                behavior = Behaviors.TextArea
                color = defTxtColor
              }
            ]
          }
        ]
      }
      currentItem.itemtype == "vehicle" ? null : {
        flow = FLOW_HORIZONTAL
        gap = bigPadding * 2
        children = [
          mkCounter(itemMaxCount, countWatched),
          Bordered(loc("btn/upgrade/allItems"),
            @() countWatched(itemMaxCount),
            {
              margin = 0
              size = [ SIZE_TO_CONTENT, hdpx(40)]
              cursor = normalTooltipTop
              onHover = function(on) {
                setTooltip(on ? loc("btn/upgrade/allItemsTooltip") : null)
              }
            })
        ]
      }
    ]
  }
}

let mkUpgradeItemButtons = function(guids, priceOptions, count) {
  local payData = []
  foreach (option in priceOptions){
    local ordersGuids = getPayItemsData({ [option.orderTpl] = option.orderReq * count },
      curCampItems.value)
    if (ordersGuids != null)
      payData.append(option.__merge({ordersGuids}))
  }

  let buttons = payData.map(@(order) {
    text = ""
    action = @() upgradeItem(mkGuidsCountTbl(guids, count),
      order.ordersGuids, @(_) markUpgradesUsed())
    customStyle = {
      textCtor = @(_textField, params, handler, group, sf)
        textButtonTextCtor({
          children = {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            margin = textMargin
            children = mkTextRow(loc("btn/upgrade/useOrders"),
              @(t) txt(t).__update({
                color = sf & S_HOVER ? TextHover : TextNormal
              }, body_txt),
              {
                ["{orders}"] = mkItemCurrency({ //warning disable: -forgot-subst
                  currencyTpl = order.orderTpl
                  count = order.orderReq * count
                  textStyle = {
                    color = sf & S_HOVER ? TextHover : TextNormal
                  }.__update(body_txt)
                })
              })
          }
        }, params, handler, group, sf)
    }.__update(primaryFlatButtonStyle)
  }).append({ text = loc("Cancel"), isCancel = true })

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
      }.__update(h2_txt)
      {
        flow = FLOW_HORIZONTAL
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("needMoreOrders")
          }.__update(h2_txt)
          {
            flow = FLOW_HORIZONTAL
            gap = {
              rendObj = ROBJ_TEXT
              text = loc("mainmenu/or")
              vplace = ALIGN_BOTTOM
              padding = bigPadding
            }.__update(sub_txt)
            children = currencyData.map(@(curr) {
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              children = [
                {
                  rendObj = ROBJ_TEXT
                  text = curr.orderReq - curr.ordersInStock
                  color = HighlightFailure
                }.__update(h2_txt)
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
      }.__update(h2_txt)
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
      text = loc("tip/notEnoughItemsDispose", { batchSize, count = orderCount })
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
                    }.__update(body_txt),
                    {
                      ["{orders}"] = mkItemCurrency({ //warning disable: -forgot-subst
                        currencyTpl = orderTpl
                        count = orderCount * countWatched.value / batchSize
                        textStyle = {
                          color = sf & S_HOVER ? TextHover : TextNormal
                        }.__update(body_txt)
                      })
                    }
                  )
                }
              }, params, handler, group, sf)
            hotkeys = [[ "^J:Y | Enter | Space" ]]
          }.__update(primaryFlatButtonStyle)
        }
    { text = loc("Cancel"), isCancel = true }
  ]

  local children = mkItemWithMods({
    item = currentItem.__merge({ count = 1 })
    itemSize = [7.0 * unitSize, 2.0 * unitSize]
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
            itemSize = [7.0 * unitSize, 2.0 * unitSize]
            isInteractive = false
          })
          upgradesList.len() <= 0 ? null : {
            rendObj = ROBJ_TEXTAREA
            size = [flex(), SIZE_TO_CONTENT]
            text = "\n".join(upgradesList)
            behavior = Behaviors.TextArea
            color = defTxtColor
          }
        ]
      }
    ]
  }

  let guidsCount = guids.len()
  let content = {
    size = [sw(90), SIZE_TO_CONTENT]
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
      }.__update(body_txt)
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
