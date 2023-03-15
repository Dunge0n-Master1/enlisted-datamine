from "%enlSqGlob/ui_library.nut" import *

let shopItemClick = require("shopItemClick.nut")
let armySelectUi = require("%enlist/army/armySelectionUi.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")

let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { makeVertScroll, styling } = require("%ui/components/scrollbar.nut")
let { colFull, colPart, columnGap } = require("%enlSqGlob/ui/designConst.nut")
let { curArmyItemsByGroup, curGroupIdx } = require("shopState.nut")
let { mkShopGroup, mkShopItem } = require("shopPackage.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { shopItemContentCtor, curUnseenAvailShopGuids } = require("armyShopState.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let { markShopItemSeen } = require("%enlist/shop/unseenShopItems.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")


let smallOffset = (columnGap / 3).tointeger()
let contentWidth = colFull(18)
let blinkUnseenIcon = blinkUnseen.__merge({ margin = smallOffset })

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })


let shopNavigationUi = @() {
  watch = [curArmyItemsByGroup, curGroupIdx]
  size = flex()
  flow = FLOW_VERTICAL
  gap = columnGap
  children = curArmyItemsByGroup.value.map(@(group, idx)
    mkShopGroup(group.id, curGroupIdx.value == idx, @() curGroupIdx(idx))
  )
}


let function navigationUi() {
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = colPart(1)
    children = [
      armySelectUi
      shopNavigationUi
    ]
  }
}

let function shopItemAction(sItem, armyId, content) {
  let { squads = [] } = sItem
  if (squads.filter(@(s) s.armyId == armyId)?[0] != null) {
    shopItemClick(sItem)
    return
  }

  let { items = {} } = content
  if (items.len() > 0) {
    viewShopItemsScene(sItem)
    return
  }

  shopItemClick(sItem)
}

let function mkShopItemCard(sItem, offers, army) {
  let itemGuid = sItem.guid
  let { guid = "", level = 0 } = army
  let crateContent = shopItemContentCtor(sItem)

  let { requirements = null } = sItem
  let { armyLevel = 0, campaignGroup = CAMPAIGN_NONE } = requirements
  let offer = offers?[itemGuid]

  return function() {
    let content = crateContent == null ? null : crateContent.value?.content
    let templates = allItemTemplates.value
    let reqFreemium = campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value
    let hasNotifier = curUnseenAvailShopGuids.value?[itemGuid] ?? false
    let lockTxt = armyLevel > level ? loc("levelInfo", { level = armyLevel })
      : reqFreemium ? loc("shopItemReqFreemium")
      : ""

    let clickCb = @() shopItemAction(sItem, guid, content)
    let hoverCb = function(on) {
      if (hasNotifier)
        hoverHoldAction("markSeenShopItem", { guid, itemGuid },
          @(v) markShopItemSeen(v.guid, v.itemGuid))(on)
    }

    return {
      watch = [crateContent, curUnseenAvailShopGuids, needFreemiumStatus, allItemTemplates]
      children = [
        mkShopItem(guid, sItem, offer, content, templates, lockTxt, clickCb, hoverCb)
        hasNotifier ? blinkUnseenIcon : null
      ]
    }
  }
}

let function contentUi() {
  let sItems = curArmyItemsByGroup.value?[curGroupIdx.value].goods ?? []
  let offers = offersByShopItem.value
  let army = curArmyData.value
  gui_scene.resetTimeout(0.01, @() anim_skip("unhover_anim"))
  return {
    watch = [curArmyItemsByGroup, curGroupIdx, offersByShopItem, curArmyData]
    size = [contentWidth, flex()]
    children = makeVertScroll({
      size = [contentWidth, SIZE_TO_CONTENT]
      children = wrap(
        sItems.map(@(sItem) mkShopItemCard(sItem, offers, army)),
        {
          width = contentWidth
          vGap = columnGap
          hGap = columnGap
        }
      )
    }, {
      size = flex()
      rootBase = class {
        behavior = Behaviors.Pannable
        wheelStep = 1
      }
      styling = scrollStyle
    })
  }
}


return {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = columnGap
  margin = [colPart(1.8), 0, 0, 0]
  children = [
    navigationUi
    contentUi
  ]
}