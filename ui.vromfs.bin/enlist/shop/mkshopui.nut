from "%enlSqGlob/ui_library.nut" import *

let shopItemClick = require("shopItemClick.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")

let { Bordered } = require("%ui/components/txtButton.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { fontMedium, fontLarge, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { makeVertScroll, styling } = require("%ui/components/scrollbar.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { shopItemContentCtor, curUnseenAvailShopGuids } = require("armyShopState.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let { markShopItemSeen, markShopItemOpened } = require("%enlist/shop/unseenShopItems.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let {
  onShopAttach, onShopDetach, mkShopState, curGroupIdx, curFeaturedIdx, chapterIdx
} = require("shopState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let {
  defTxtColor, colFull, colPart, columnGap, smallPadding, midPadding, darkTxtColor,
  contentOffset, titleTxtColor, hoverSlotBgColor, largePadding
} = require("%enlSqGlob/ui/designConst.nut")
let {
  mkBaseShopItem, mkLowerShopItem, lowerSlotSize, mkShopFeatured, mkDiscountBar
} = require("shopPackage.nut")
let buySquadWindow = require("%enlist/shop/buySquadWindow.nut")
let { mkProductView } = require("%enlist/shop/shopPkg.nut")
let starterPack = require("%enlist/soldiers/starterPackPromoWnd.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")


let mkShopGroup = function(group, isSelected, onClick) {
  let text = utf8ToUpper(loc(group.locId ?? $"shopGroup/{group.id}"))

  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    fillColor = sf & S_HOVER ? hoverSlotBgColor : 0
    borderColor = Color(255,255,255)
    borderWidth = isSelected ? [0,0,smallPadding,0] : 0
    size = [SIZE_TO_CONTENT, colPart(0.75)]
    behavior = Behaviors.Button
    onClick
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
      active = "ui/enlist/button_action"
    }
    padding = [smallPadding, columnGap]
    maxWidth = colPart(12)
    minWidth = colPart(1)
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXT
      text
      color = (sf & S_HOVER)
        ? darkTxtColor
        : isSelected ? titleTxtColor : defTxtColor
    }.__update(fontLarge)
  })
}
let shopGroupTxtHgt = calc_str_box({rendObj = ROBJ_TEXT text= "H"})[1]

const SWITCH_SEC = 8.0

let contentWidth = colFull(20)

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let paginatorTimer = Watched(SWITCH_SEC)

let featuredPaginator = mkDotPaginator({
  id = "featured"
  pageWatch = curFeaturedIdx
  dotSize = columnGap
  switchTime = paginatorTimer
})

let itemsToMarkSeen = {}
local openedTs = -1
local currentTabHasDelay = false
const VIEWED_SECONDS = 5

let markItemsSeen = function(hasDelay) {
  if (!hasDelay || (serverTime.value - openedTs > VIEWED_SECONDS)) {
    itemsToMarkSeen.each(function(itemList, armyId) {
      defer(@() markShopItemSeen(armyId, itemList))
    })
  }
  itemsToMarkSeen.clear()
  openedTs = serverTime.value
}

let locSpecialOffer = loc("specialOfferShort")

let mkDiscount = @(discount) mkDiscountBar({
  rendObj = ROBJ_TEXT
  text = discount > 0 ? $"-{discount}%" : locSpecialOffer
  color = darkTxtColor
}.__update(fontMedium)).__update({
  vplace = ALIGN_BOTTOM
  pos = [0, shopGroupTxtHgt]
})

let unseenGuids = function(goods, unseenVal) {
  let res = []
  foreach (item in goods) {
    let { guid } = item
    if (guid in unseenVal)
      res.append(guid)
  }
  return res
}

let function buildShopUi() {
  let {
    curShopItemsByGroup,
    curShopDataByGroup,
    curFeaturedByGroup,
    switchGroup,
    autoSwitchNavigation
  } = mkShopState()

  let switchGroupKey = mkHotkey("X | J:X", switchGroup)

  let function shopNavigationUi() {
    let dataByGroup = curShopDataByGroup.value
    return {
      watch = [curShopItemsByGroup, curShopDataByGroup, curGroupIdx, isGamepad]
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      gap = columnGap
      children = curShopItemsByGroup.value.map(function(group, idx) {
        let { hasUnseen = false, unopened = [], discount = 0, showSpecialOffer = false } = dataByGroup?[group.id]
        let hasDiscount = discount > 0 || showSpecialOffer
        let discountComp = hasDiscount ? mkDiscount(discount) : null
        return {
          valign = ALIGN_CENTER
          children = [
            mkShopGroup(group, curGroupIdx.value == idx, function() {
              curFeaturedIdx(0)
              chapterIdx(-1)
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
                !hasDiscount ? null : discountComp
              ]
            }
          ]
        }
      })
      .append(isGamepad.value ? switchGroupKey : null)
    }
  }

  let function shopItemAction(sItem) {
    shopItemClick(sItem)
  }

  let function mkShopItemCard(
    sItem, idx, offers, army, cb, isFeatured = false, isNarrow = false
  ) {
    if (sItem == null)
      return null

    let itemGuid = sItem?.guid
    let { guid = "", level = 0 } = army
    let crateContent = shopItemContentCtor(sItem)

    let { requirements = null } = sItem
    let { armyLevel = 0, campaignGroup = CAMPAIGN_NONE } = requirements
    let offer = offers?[itemGuid]
    let squad = sItem?.squads[0]
    let hasNotifier = Computed(@() curUnseenAvailShopGuids.value?[itemGuid] ?? false)
    let hoverCb = function(on) {
      if (hasNotifier.value)
        hoverHoldAction("markSeenShopItem", { guid, itemGuid },
          @(v) markShopItemSeen(v.guid, v.itemGuid))(on)
    }
    let unseenComp = @() {
      watch = hasNotifier
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      children = hasNotifier.value ? unblinkUnseen : null
    }

    return function() {
      let content = crateContent == null ? null : crateContent.value?.content
      let clickCb = @() cb(sItem)
      let templates = allItemTemplates.value
      let reqFreemium = campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value
      let lockTxt = armyLevel > level ? loc("levelInfo", { level = armyLevel })
        : reqFreemium ? loc("shopItemReqFreemium")
        : ""

      let infoCb = sItem?.isStarterPack ? @() starterPack(sItem)
        : squad == null || armyLevel > level ? null
        : @() buySquadWindow({
            shopItem = sItem
            productView = mkProductView(sItem, allItemTemplates)
            armyId = squad.armyId
            squadId = squad.id
          })

      let itemCtor = isNarrow ? mkLowerShopItem : mkBaseShopItem
      let itemView = isFeatured
        ? mkShopFeatured(guid, sItem, offer, content, templates, lockTxt, clickCb, hoverCb, infoCb)
        : itemCtor(idx, guid, sItem, offer, content, templates,
            lockTxt, clickCb, hoverCb, null, infoCb, unseenComp)
      return {
        key = itemGuid
        watch = [crateContent, needFreemiumStatus, allItemTemplates]
        children = itemView
      }
    }
  }


  let mkFeatured = @(army, featured, offers) {
    children = [
      function() {
        let sItem = featured?[curFeaturedIdx.value] ?? featured?[0]
        return {
          watch = curFeaturedIdx
          children = mkShopItemCard(sItem, 0, offers, army, shopItemAction, true)
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

  let backButtonUi = freeze({
    size = lowerSlotSize
    children = Bordered(loc("mainmenu/btnBack"), @() chapterIdx(-1), {
      size = flex()
      xmbNode = XmbNode()
    })
  })

  let unseenItemsForGroup = function(group) {
    let { goods, chapters } = group
    return {
      unseenList = unseenGuids(goods, curUnseenAvailShopGuids.value)
      chapters = chapters == null ? null
        : chapters.map(@(chapter) unseenGuids(chapter.goods, curUnseenAvailShopGuids.value))
    }
  }

  let watch = freeze([
    curShopItemsByGroup, curFeaturedByGroup, curGroupIdx, chapterIdx,
    offersByShopItem, curArmyData
  ])

  let function contentUi() {
    let res = {
      watch
      xmbNode = XmbContainer({
        canFocus = @() false
        scrollSpeed = 10.0
        isViewport = true
      })
    }
    let curGroup = curShopItemsByGroup.value?[curGroupIdx.value]
    let { id = "", goods = [], chapters = null, autoseenDelay = false } = curGroup

    let featured = curFeaturedByGroup.value?[id] ?? []
    if (goods.len() == 0 && chapters == null && featured.len() == 0)
      return res.__update({
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = defTxtColor
        size = flex()
        text = loc("shop/emptyTab")
      }, fontXLarge)

    let offers = offersByShopItem.value
    let army = curArmyData.value
    gui_scene.resetTimeout(0.01, @() anim_skip("unhover_anim"))

    let shopContent = chapters != null || featured.len() == 0 ? []
      : [mkFeatured(army, featured, offers)]

    if (chapters == null)
      shopContent.extend(goods.map(@(sItem, idx)
        mkShopItemCard(sItem, idx, offers, army, shopItemAction)))
    else if (chapterIdx.value < 0)
      shopContent.extend(chapters.map(@(chapter, idx)
        mkShopItemCard(chapter.container, idx, offers, army, @(...) chapterIdx(idx), false, true))
          .filter(@(i) i != null))
    else
      shopContent
        .append(backButtonUi)
        .extend(chapters[chapterIdx.value].goods.map(@(sItem, idx)
          mkShopItemCard(sItem, idx, offers, army, shopItemAction, false, true)))

    markItemsSeen(currentTabHasDelay)
    currentTabHasDelay = autoseenDelay
    if (curGroup != null && (chapters == null || chapterIdx.value >= 0)) {
      let unseenForGroup = unseenItemsForGroup(curGroup)
      let unseenList = unseenForGroup?.chapters[chapterIdx.value] ?? unseenForGroup?.unseenList
      itemsToMarkSeen[army.guid] <- clone unseenList
    }

    return res.__update({
      hplace = ALIGN_CENTER
      size = [contentWidth, flex()]
      children = makeVertScroll(
        {
          size = [contentWidth, SIZE_TO_CONTENT]
          children = wrap(shopContent, {
            width = contentWidth
            vGap = columnGap
            hGap = columnGap
          })
        },
        {
          size = flex()
          rootBase = {
            behavior = Behaviors.Pannable
            wheelStep = 1
          }
          styling = scrollStyle
        }
      )
      onDetach = @() markItemsSeen(currentTabHasDelay)
    })
  }


  return {
    size = flex()
    flow = FLOW_VERTICAL
    margin = [contentOffset,0,0,0]
    gap = columnGap * 2
    children = [
      armySelectUi
      {
        size = flex()
        function onAttach() {
          onShopAttach()
          autoSwitchNavigation()
        }
        onDetach = onShopDetach
        flow = FLOW_VERTICAL
        gap = largePadding
        children = [
          shopNavigationUi
          contentUi
        ]
      }
    ]
  }
}

return {
  buildShopUi
}