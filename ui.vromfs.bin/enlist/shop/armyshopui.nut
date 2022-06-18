from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let JB = require("%ui/control/gui_buttons.nut")
let campaignTitle = require("%enlist/campaigns/campaign_title_small.ui.nut")
let buySquadWindow = require("buySquadWindow.nut")
let { makeVertScroll } = require("%darg/components/scrollbar.nut")
let { safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { Transp } = require("%ui/components/textButton.nut")
let { borderColor } = require("%ui/style/colors.nut")

let viewShopItemsScene = require("viewShopItemsScene.nut")
let armySelect = require("%enlist/soldiers/army_select.ui.nut")
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
let mkNotifier = require("%enlist/components/mkNotifier.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { markShopItemSeen } = require("%enlist/shop/unseenShopItems.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")
let freemiumPromo = require("%enlist/currency/pkgFreemiumWidgets.nut")


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
  keepAspect = true
  image = Picture($"!ui/skin#logistics_icon.svg:{CONT_ICON_SIZE}:{CONT_ICON_SIZE}:K")
}

let function mkShopItemCard(shopItem, armyData) {
  let { guid, offerContainer = "" } = shopItem
  let squad = shopItem?.squads[0]
  let armyId = armyData?.guid ?? ""
  let currentLevel = armyData?.level ?? 0
  let { armyLevel = 0, isFreemium = false } = shopItem?.requirements
  let isLocked = armyLevel > currentLevel || (isFreemium && needFreemiumStatus.value)

  let stateFlags = Watched(0)
  let isGroupContainer = offerContainer != ""

  let containerIcon = isGroupContainer ? contIcon : null
  let crateContent = shopItemContentCtor(shopItem)
  return function() {
    let sf = stateFlags.value
    let hasUnseenSignal = curUnseenAvailShopGuids.value?[shopItem.guid] ?? false
    let unseenSignalObj = !hasUnseenSignal ? null
      : isGroupContainer ? mkNotifier(loc("hint/newShopItemsAvailable"))
      : unseenSignal()
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
      onHover = @(on) setTooltip(on
        ? makeCrateToolTip(crateContent)
        : null)
      onClick = function() {
        clickShopItem(shopItem, curArmyData.value?.level ?? 0)
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
              onInfoCb = squad == null || armyLevel > currentLevel ? null
                : @() buySquadWindow({
                      shopItem
                      productView = mkProductView(shopItem, allItemTemplates)
                      armyId = squad.armyId
                      squadId = squad.id
                    })
              unseenSignalObj
              crateContent
              itemTemplates = allItemTemplates
            })
            isGroupContainer ? null
              : armyLevel > currentLevel ? mkLevelLockLine(armyLevel)
              : mkShopItemPriceLine(shopItem)
          ]
        }
        hoverBox(sf, CARD_MAX_WIDTH)
      ]
    }
  }
}

let function mkShopLine(line, config = {}) {
  let count = (line ?? []).len()
  if (count == 0)
    return null

  let height = fsh(config?.height ?? CARD_DEFAULT_HEIGHT)
  return @() {
    watch = curArmyData
    size = [flex(), height]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = line.map(@(shopItem) mkShopItemCard(shopItem, curArmyData.value))
  }
}

let function shopContentUi() {
  let sConfig = shopConfig.value
  let allLines = curArmyShopLines.value
  let res = {
    watch = [curGroup, curArmyShopLines, shopConfig, safeAreaSize]
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
      children = allLines.map(@(line, idx) mkShopLine(line, curGroupV
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
    @() setCurArmyShopFolder(groupItem?.offerContainer),
    {
      margin = 0
      textMargin = fsh(1)
      borderWidth = [0,0,hdpx(1),0]
      hotkeys = !hasHotkey ? null
        : [["^{0} | Esc".subst(JB.B), {
            action = @() setCurArmyShopFolder(groupItem?.offerContainer)
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
        armySelect()
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
          children = [
            mainContent
            @() {
              watch = needFreemiumStatus
              children = needFreemiumStatus.value
                ? freemiumPromo("shop_section", null, {
                    size = [hdpx(600), SIZE_TO_CONTENT]
                    margin = [bigPadding,0,0,0]
                  })
                : null
            }
          ]
        }
        campaignTitle
      ]
    : mkDisabledSectionBlock({ descLocId = "menu/lockedByCampaignDesc" })
})
