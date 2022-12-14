from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let mkItemWithMods = require("%enlist/soldiers/mkItemWithMods.nut")
let { TextNormal, TextHover, textMargin
} = require("%ui/components/textButton.style.nut")
let getPayItemsData = require("%enlist/soldiers/model/getPayItemsData.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { upgradeItem, disposeItem } = require("%enlist/soldiers/model/itemActions.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { defTxtColor, bigPadding, unitSize, warningColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { diffUpgrades } = require("itemDetailsPkg.nut")
let { markUpgradesUsed } = require("%enlist/soldiers/model/unseenUpgrades.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { primaryFlatButtonStyle } = require("%enlSqGlob/ui/buttonsStyle.nut")
let { mkCounter } = require("%enlist/shop/mkCounter.nut")

let mkTextArea = @(txt) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  color = defTxtColor
  text = txt
}.__update(body_txt)

let mkFaComp = @(text) faComp(text, {
  size = [SIZE_TO_CONTENT, 2.0 * unitSize]
  valign = ALIGN_CENTER
  fontSize = hdpx(30)
  color = defTxtColor
})

let arrowComp = mkFaComp("arrow-circle-right")

let mkUpgradeItemInfo = kwarg(
  @(currentItem, upgradedItem, orderViews, upgradesList) {
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
          {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_RIGHT
            valign = ALIGN_CENTER
            gap = fsh(2)
            children = orderViews
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
    ]
  })

let mkUpgradeItemButtons = kwarg(
  function(iGuid, ordersData) {
    let buttons = ordersData.map(@(order){
      text = ""
      action = @() upgradeItem(iGuid, order.ordersGuids, @(_) markUpgradesUsed())
      customStyle = {
        textCtor = @(_textField, params, handler, group, sf)
          textButtonTextCtor({
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
                  count = order.orderReq
                  textStyle = {
                    color = sf & S_HOVER ? TextHover : TextNormal
                  }.__update(body_txt)
                })
              })
          }, params, handler, group, sf)
      }.__update(primaryFlatButtonStyle)
    }).append({ text = loc("Cancel"), isCancel = true })

    return buttons
})


let showNoOrdersMsgbox = @(currencyData) msgbox.showMessageWithContent({
  content = {
    size = [sw(90), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = fsh(5)
    halign = ALIGN_CENTER
    children = [
      mkTextArea(loc("noItemPartsToUpgrade"))
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = bigPadding
        children = [
          txt({
            text = loc("notEnoughOrders")
            hplace = ALIGN_CENTER
            color = warningColor
          }.__update(sub_txt))
          {
            flow = FLOW_HORIZONTAL
            gap = txt({
              text = loc("mainmenu/or")
              vplace = ALIGN_BOTTOM
              padding = bigPadding
              color = warningColor
            }).__update(sub_txt)
            children = currencyData.map(@(curr) mkItemCurrency(
              { currencyTpl = curr.orderTpl, count = curr.orderReq - curr.ordersInStock }))
          }
        ]
      }
    ]
  }
  buttons = [{ text = loc("Ok"), isCancel = true, isCurrent = true }]
})

let function openUpgradeItemMsg(currentItem, upgradeData) {
  let {
    iGuid, armyId, upgradeitem, priceOptions, hasEnoughOrders
  } = upgradeData
  if (iGuid == null || (currentItem?.guid ?? "") == "") {
    msgbox.show({ text = loc("noFreeItemToUpgrade") })
    return
  }

  if (!hasEnoughOrders) {
    showNoOrdersMsgbox(priceOptions)
    return
  }

  local payData = []
  foreach (option in priceOptions){
    local ordersGuids = getPayItemsData({ [option.orderTpl] = option.orderReq }, curCampItems.value)
    if (ordersGuids != null)
      payData.append(option.__merge({ordersGuids}))
  }

  local upgradedItem = findItemTemplate(allItemTemplates, armyId, upgradeitem)
  if (upgradedItem == null) // it's definitely setup error but it shouldn't break ui
    return

  upgradedItem = currentItem.__merge(upgradedItem)

  let upgradesList = diffUpgrades(currentItem)

  let orderViews = payData.map(@(option)
    mkItemCurrency({
      currencyTpl = option.orderTpl,
      count = option.ordersInStock,
      textStyle = { color = TextNormal }.__update(body_txt)
    })
  )

  msgbox.showMessageWithContent({
    content = mkUpgradeItemInfo({
      currentItem, upgradedItem, orderViews, upgradesList
    })
    buttons = mkUpgradeItemButtons({
      iGuid,
      ordersData = payData
    })
  })
}

let function openDisposeItemMsg(currentItem, disposeData) {
  let {
    armyId, itemBaseTpl, orderTpl, orderCount, isDestructible, isRecyclable, guids
  } = disposeData
  if (guids == null) {
    msgbox.show({ text = loc("unlinkBeforeDispose") })
    return
  }
  let countWatched = Watched(1)
  let buttons = [
    isRecyclable
      ? {
          text = loc("btn/recycle")
          isCurrent = true
          action = @() disposeItem(guids, countWatched.value)
          customStyle = {
            hotkeys = [[ "^J:Y | Enter | Space" ]]
          }
        }
      : {
          text = ""
          isCurrent = true
          action = @() disposeItem(guids, countWatched.value)
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
                        count = orderCount * countWatched.value
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
      !isDestructible || guidsCount <= 1 ? null : mkCounter(guidsCount, countWatched)
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
