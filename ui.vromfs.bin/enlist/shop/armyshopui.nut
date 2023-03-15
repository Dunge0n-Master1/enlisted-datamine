from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let JB = require("%ui/control/gui_buttons.nut")
let campaignTitle = require("%enlist/campaigns/campaign_title_small.ui.nut")
let buySquadWindow = require("buySquadWindow.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { Transp } = require("%ui/components/textButton.nut")
let { borderColor } = require("%ui/style/colors.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { bigPadding, defBgColor, scrollbarParams, titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { curUnseenAvailShopGuids, curArmyShopLines, shopConfig, purchaseInProgress,
  curArmyShopInfo, shopItemToShow, shopItemContentCtor, setCurArmyShopFolder,
  isShopVisible, hasShopSection, shopItemsToHighlight, curArmyShopFolder
} = require("armyShopState.nut")
let clickShopItem = require("clickShopItem.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { mkDisabledSectionBlock } = require("%enlist/mainMenu/disabledSections.nut")
let { makeCrateToolTip } = require("%enlist/items/crateInfo.nut")
let { mkShopItemView, mkLevelLockLine, mkShopItemPriceLine, mkProductView
} = require("shopPkg.nut")
let { mkLockByCampaignProgress } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { mkNotifierNoBlink } = require("%enlist/components/mkNotifier.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { markShopItemSeen } = require("%enlist/shop/unseenShopItems.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { freemiumWidget } = require("%enlSqGlob/ui/mkPromoWidget.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let starterPack = require("%enlist/soldiers/starterPackPromoWnd.nut")


const SHOP_CONTAINER_WIDTH = 120 // sh
const CARD_DEFAULT_HEIGHT  = 40  // sh
let CONT_ICON_SIZE = hdpx(40)
let CARD_MAX_WIDTH = fsh(80)

let curGroup = Computed(@()
  curArmyShopFolder.value.path?[curArmyShopFolder.value.path.len() - 1]
)

let shopScroll = ScrollHandler()

let repeatLast = @(arr, idx) (arr?.len() ?? 0) == 0 ? null
  : arr[min(idx, arr.len() - 1)]

local function highlightItems(items = null){
  items = items ?? shopItemsToHighlight.value
  if (items == null)
    return

  items.each(@(v) anim_start(v.guid))
}

let function scrollToCurrentItems() {
  let targetItem = (shopItemToShow.value ?? shopItemsToHighlight.value ?? [])
    .findvalue(@(v) (v?.offerGroup ?? "") == curGroup.value?.offerContainer)
  if (targetItem == null)
    return

  let guid = targetItem.guid
  shopScroll.scrollToChildren(
    @(desc) desc?.guid == guid,
    3, false, true)

  if (shopItemsToHighlight.value == null)
    return

  highlightItems()
  shopItemsToHighlight(shopItemsToHighlight.value
    .filter(@(v) (v?.offerGroup ?? "") != curGroup.value?.offerContainer))
}

let hoverBox = @(sf, maxWidth) {
  size = flex()
  maxWidth
  rendObj = ROBJ_BOX
  borderWidth = sf & S_HOVER ? hdpx(4) : hdpx(1)
  borderColor = borderColor(sf, false)
}

let contIcon = {
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_LEFT
  flipX = true
  size = array(2, CONT_ICON_SIZE)
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"!ui/skin#logistics_icon.svg:{CONT_ICON_SIZE}:{CONT_ICON_SIZE}:K")
}

let mkShopNotifier = @(locId)
  mkNotifierNoBlink(locId, { margin = hdpx(3) })
let shopGroupNotifier = mkShopNotifier(loc("hint/newShopItemsAvailable"))
let shopItemNotifier = mkShopNotifier(loc("hint/newShopItemAvailable"))

let function mkShopItemCard(shopItem, offersByItem, armyData, isNarrow) {
  let { guid, offerContainer = "", curItemCost = {}, discountInPercent = 0,
    unlockCampaign = CAMPAIGN_NONE, squads = [], isStarterPack = false } = shopItem
  let armyId = armyData?.guid ?? ""
  let squad = squads.filter(@(s) s.armyId == armyId)?[0]
  let offer = offersByItem?[guid]
  let currentLevel = armyData?.level ?? 0
  let { armyLevel = 0, campaignGroup = CAMPAIGN_NONE } = shopItem?.requirements
  let stateFlags = Watched(0)
  let isGroupContainer = offerContainer != ""

  let containerIcon = isGroupContainer ? contIcon : null
  let crateContent = shopItemContentCtor(shopItem)
  let onInfoCb = isStarterPack ? @() starterPack(shopItem)
    : unlockCampaign != CAMPAIGN_NONE ? @() freemiumWnd(unlockCampaign)
    : squad != null ? @() buySquadWindow({
        shopItem
        productView = mkProductView(shopItem, allItemTemplates)
        armyId = squad.armyId
        squadId = squad.id
      })
    : null

  return function() {
    let sf = stateFlags.value
    let isLocked = armyLevel > currentLevel
      || (campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value)
    let hasUnseenSignal = curUnseenAvailShopGuids.value?[shopItem.guid] ?? false
    let unseenSignalObj = !hasUnseenSignal ? null
      : isGroupContainer ? shopGroupNotifier
      : shopItemNotifier
    return {
      watch = [stateFlags, curUnseenAvailShopGuids, crateContent, needFreemiumStatus]
      rendObj = ROBJ_SOLID
      guid
      size = flex()
      maxWidth = CARD_MAX_WIDTH
      halign = ALIGN_CENTER
      color = defBgColor
      behavior = Behaviors.Button
      onElemState = @(newSF) stateFlags(newSF)
      onHover = function(on) {
        setTooltip(on ? makeCrateToolTip(crateContent) : null)
        if (!isGroupContainer && hasUnseenSignal)
          hoverHoldAction("markSeenShopItem", { armyId, guid },
            @(v) markShopItemSeen(v.armyId, v.guid))(on)
      }
      onClick = function() {
        clickShopItem(shopItem, armyData?.level ?? 0)
        if (!isGroupContainer && hasUnseenSignal)
          markShopItemSeen(armyId, guid)
      }
      clipChildren = true
      children = [
        {
          size = flex()
          maxWidth = CARD_MAX_WIDTH
          flow = FLOW_VERTICAL
          children = [
            mkShopItemView({
              shopItem
              containerIcon
              isLocked
              purchasingItem = purchaseInProgress
              onCrateViewCb = @() viewShopItemsScene(shopItem)
              onInfoCb
              unseenSignalObj
              crateContent
              itemTemplates = allItemTemplates
              showVideo = shopItem?.video && sf
              showDiscount = (isGroupContainer || curItemCost.len() > 0) && discountInPercent > 0
            })
            isGroupContainer ? null
              : armyLevel > currentLevel ? mkLevelLockLine(armyLevel)
              : mkShopItemPriceLine(shopItem, offer, isNarrow)
          ]
        }
        hoverBox(sf, CARD_MAX_WIDTH)
      ]
    }
  }
}

let function mkShopLine(line, offersByItem, config = {}) {
  let count = (line ?? []).len()
  if (count == 0)
    return null

  let isNarrow = count >= 3
  let height = fsh(config?.height ?? CARD_DEFAULT_HEIGHT)
  return @() {
    watch = curArmyData
    size = [flex(), height]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = line.map(@(shopItem)
      mkShopItemCard(shopItem, offersByItem, curArmyData.value, isNarrow))
  }
}

let function shopContentUi() {
  let sConfig = shopConfig.value
  let allLines = curArmyShopLines.value
  let offersByItem = offersByShopItem.value
  let res = {
    watch = [curGroup, curArmyShopLines, shopConfig, offersByShopItem, safeAreaSize]
    valign = ALIGN_CENTER
  }
  if (allLines.len() == 0)
    return res

  let curGroupV = curGroup.value ?? {}
  let rowsHeight = curGroupV?.rowsHeight ?? sConfig?.rowsHeight
  let shopWidth = min(
    fsh(sConfig?.container.widthScale ?? SHOP_CONTAINER_WIDTH),
    safeAreaSize.value[0]
  )
  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = makeVertScroll({
      key = curGroupV
      size = [shopWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = allLines.map(@(line, idx) mkShopLine(line, offersByItem, curGroupV
        .__merge({ height = repeatLast(rowsHeight, idx) })))
      onAttach = @() gui_scene.resetTimeout(0.1, scrollToCurrentItems)
    }, scrollbarParams.__merge({ scrollHandler = shopScroll }))
  })
}

let mkGroupBtn = @(groupItem, isLast, hasHotkey) isLast
  ? txt({
      text = loc(groupItem?.nameLocId)
      margin = fsh(1)
      color = titleTxtColor
    }.__update(body_txt))
  : Transp(loc(groupItem?.nameLocId ?? "shopMainMenu"),
      function() {
        setCurArmyShopFolder(groupItem?.offerContainer)
        shopScroll.scrollToY(0)
      },
      {
        margin = 0
        textMargin = fsh(1)
        borderWidth = [0,0,hdpx(1),0]
        hotkeys = !hasHotkey ? null
          : [[$"^{JB.B} | Esc", {
              action = function() {
                setCurArmyShopFolder(groupItem?.offerContainer)
                shopScroll.scrollToY(0)
              }
              description = { skip = true }
            }]]
      })

let rightArrow = faComp("caret-right", {padding = fsh(1)})

let groupsChainUi = function() {
  let groupsChain = curArmyShopFolder.value.path
  let gChainLen = groupsChain.len()
  let chainChildren = []
  if (gChainLen > 0)
    chainChildren.append(mkGroupBtn(null, false, gChainLen == 1))
      .extend(groupsChain.map(@(v, idx)
        mkGroupBtn(v, idx == gChainLen - 1, idx == gChainLen - 2)))

  return {
    watch = curArmyShopFolder
    flow = FLOW_HORIZONTAL
    gap = rightArrow
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = chainChildren
  }
}

let msg = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = Color(180,180,180)
  halign = ALIGN_CENTER
  text
}.__update(body_txt)

let noGoodsMessageUi = @(unlockLevel) {
  size = [fsh(80), SIZE_TO_CONTENT]
  pos = [0, -sh(5)]
  padding = fsh(5)
  rendObj = ROBJ_SOLID
  color = defBgColor
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    msg(loc("menu/enlistedShopDesc"))
    unlockLevel <= 0 ? null : msg(loc("shop/unlockByArmyLevel", { unlockLevel }))
  ]
}

let mainContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        armySelectUi
        groupsChainUi
      ]
    }
    @() {
      watch = [isShopVisible, curArmyShopInfo]
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = (isShopVisible.value || curArmyShopInfo.value.hasTemporary)
          && curArmyShopInfo.value.goods.len() > 0
        ? shopContentUi
        : noGoodsMessageUi(curArmyShopInfo.value.unlockLevel)
    }
  ]
}

return mkLockByCampaignProgress(@() {
  watch = hasShopSection
  size = flex()
  halign = ALIGN_RIGHT
  children = hasShopSection.value
    ? [
        {
          size = flex()
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          gap = hdpx(10)
          children = [
            mainContent
            @() {
              watch = needFreemiumStatus
              children = needFreemiumStatus.value
                ? freemiumWidget("shop_section")
                : null
            }
          ]
        }
        campaignTitle
      ]
    : mkDisabledSectionBlock({ descLocId = "menu/lockedByCampaignDesc" })
})
