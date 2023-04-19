from "%enlSqGlob/ui_library.nut" import *

let shopItemClick = require("shopItemClick.nut")
let armySelectUi = require("%enlist/army/armySelectionUi.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { makeVertScroll, styling } = require("%ui/components/scrollbar.nut")
let { mkShopGroup, mkBaseShopItem, mkShopFeatured, mkDiscountBar } = require("shopPackage.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { shopItemContentCtor, curUnseenAvailShopGuids } = require("armyShopState.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let { markShopItemSeen, markShopItemOpened } = require("%enlist/shop/unseenShopItems.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { curShopItemsByGroup, curFeaturedByGroup, curShopDataByGroup,
  curGroupIdx, curFeaturedIdx
} = require("shopState.nut")
let { colFull, colPart, columnGap, smallPadding, midPadding, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


const SWITCH_SEC = 8.0

let contentWidth = colFull(20)

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let discountInfoStyle = { color = darkTxtColor }.__update(fontLarge)


let paginatorTimer = Watched(SWITCH_SEC)

let featuredPaginator = mkDotPaginator({
  id = "featured"
  pageWatch = curFeaturedIdx
  dotSize = columnGap
  switchTime = paginatorTimer
})


let function shopNavigationUi() {
  let dataByGroup = curShopDataByGroup.value
  return {
    watch = [curShopItemsByGroup, curShopDataByGroup, curGroupIdx]
    size = flex()
    flow = FLOW_VERTICAL
    gap = columnGap
    children = curShopItemsByGroup.value.map(function(group, idx) {
      let { hasUnseen = false, unopened = [], discount = 0, showSpecialOffer = false } = dataByGroup?[group.id]
      return {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [
          mkShopGroup(group.id, curGroupIdx.value == idx, function() {
            curFeaturedIdx(0)
            curGroupIdx(idx)
            markShopItemOpened(curArmyData.value?.guid, unopened)
          })
          {
            size = flex()
            padding = [0, 0, midPadding, 0]
            halign = ALIGN_RIGHT
            children = [
              !hasUnseen ? null
                : unopened.len() > 0 ? blinkUnseen
                : unblinkUnseen
              discount == 0 && !showSpecialOffer ? null
                : mkDiscountBar(
                    {
                      rendObj = ROBJ_TEXT
                      text = discount > 0 ? $"-{discount}%" : loc("specialOfferShort")
                    }.__update(discountInfoStyle), true
                  ).__update({ vplace = ALIGN_BOTTOM })
            ]
          }
        ]
      }
    })
  }
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

let function mkShopItemCard(sItem, idx, offers, army, isFeatured = false) {
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

    let itemView = isFeatured
      ? mkShopFeatured(guid, sItem, offer, content, templates, lockTxt, clickCb, hoverCb)
      : mkBaseShopItem(idx, guid, sItem, offer, content, templates, lockTxt, clickCb, hoverCb)

    return {
      watch = [crateContent, curUnseenAvailShopGuids, needFreemiumStatus, allItemTemplates]
      children = [
        itemView
        hasNotifier ? unblinkUnseen : null
      ]
    }
  }
}


let function mkFeatured(army, featured, offers) {
  return {
    children = [
      function() {
        let sItem = featured[curFeaturedIdx.value]
        return {
          watch = curFeaturedIdx
          children = mkShopItemCard(sItem, 0, offers, army, true)
        }
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = smallPadding
        vplace = ALIGN_BOTTOM
        children = featuredPaginator(featured.len())
      }
    ]
  }
}


let function contentUi() {
  let res = {
    watch = [curShopItemsByGroup, curFeaturedByGroup, curGroupIdx, offersByShopItem, curArmyData]
  }
  let curGroup = curShopItemsByGroup.value?[curGroupIdx.value]
  let { id = "", goods = [] } = curGroup
  if (goods.len() == 0)
    return res

  let featured = curFeaturedByGroup.value?[id] ?? []
  let offers = offersByShopItem.value
  let army = curArmyData.value
  gui_scene.resetTimeout(0.01, @() anim_skip("unhover_anim"))

  let shopContent = featured.len() == 0 ? [] : [mkFeatured(army, featured, offers)]
  shopContent.extend(goods.map(@(sItem, idx) mkShopItemCard(sItem, idx, offers, army)))

  return res.__update({
    size = [contentWidth, flex()]
    children = makeVertScroll({
      size = [contentWidth, SIZE_TO_CONTENT]
      children = wrap(shopContent, {
        width = contentWidth
        vGap = columnGap
        hGap = columnGap
      })
    }, {
      size = flex()
      rootBase = class {
        behavior = Behaviors.Pannable
        wheelStep = 1
      }
      styling = scrollStyle
    })
  })
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
  onAttach = @() curGroupIdx(0)
}
