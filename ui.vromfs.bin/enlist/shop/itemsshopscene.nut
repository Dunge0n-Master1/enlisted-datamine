from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let armyCurrencyUi = require("armyCurrencyUi.nut")
let clickShopItem = require("clickShopItem.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let { mkLowerShopItem, lowerSlotSize } = require("shopPackage.nut")
let { markShopItemSeen } = require("%enlist/shop/unseenShopItems.nut")
let { makeVertScroll, styling } = require("%ui/components/scrollbar.nut")
let { itemToShopItem } = require("%enlist/soldiers/model/cratesContent.nut")
let {
  curArmyItemsPrefiltered, isItemsShopOpened, shopItemContentCtor, curUnseenAvailShopGuids,
  curSuitableShopItems
} = require("armyShopState.nut")
let {
  mkSlotBgOverride, mkSlotTextareaOverride
} = require("%enlSqGlob/ui/slotPkg.nut")
let {
  colPart, colFull, columnGap, smallPadding, midPadding, defTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


const COLUMNS = 4

let defTxtStyle = { color = defTxtColor }.__update(fontSmall)

let headerHeight = colPart(2)
let cardSize = [colFull(5), colPart(4)]
let nestWidth = COLUMNS * cardSize[0] + (COLUMNS - 1) * columnGap
let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let groupIdx = Watched(0)
let tipShopItemGuid = Watched(null)

let scrollHandler = ScrollHandler()

let tipObject = {
  size = flex()
  rendObj = ROBJ_BOX
  borderWidth = 1
  animations = [{
    prop = AnimProp.opacity, from = 0, to = 0.4, duration = 1, play = true, loop = true, easing = Blink
  }]
}


let groupsData = [
  {
    groupId = "wpack_silver_pistol_group"
    locId = "items/pistol_silver"
  }
  {
    groupId = "wpack_silver_rifle_group"
    locId = "items/rifle_silver"
  }
  {
    groupId = "wpack_silver_submachine_gun_group"
    locId = "items/submachine_gun_silver"
  }
  {
    groupId = "wpack_silver_special_group"
    locId = "items/special_silver"
  }
  {
    groupId = "wpack_group"
    locId = "shop/equipment"
  }
]


let sortItems = @(a, b)
  (a?.requirements.armyLevel ?? 0) <=> (b?.requirements.armyLevel ?? 0) || a.guid <=> b.guid


let shopItemsByGroups = keepref(Computed(function() {
  let armyShopItems = curArmyItemsPrefiltered.value
  let res = groupsData.map(function(grData) {
    let shopItems = armyShopItems
      .filter(@(v) (v?.offerGroup ?? "") == grData.groupId)
      .values()
      .sort(sortItems)
    return { shopItems }.__update(grData)
  })

  return res
}))


let shopTabSize = [colFull(2), colPart(1)]

let function mkShopTab(locId, idx, idxWatched) {
  let isSelected = Computed(@() idxWatched.value == idx)
  return watchElemState(function(sf) {
    let isSelectedVal = isSelected.value
    let isActive = isSelectedVal || (sf & S_HOVER)
    return {
      watch = isSelected
      size = shopTabSize
      padding = [0, midPadding]
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = @() idxWatched(idx)
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        text = utf8ToUpper(loc(locId))
      }.__update(defTxtStyle, mkSlotTextareaOverride(isActive))
    }.__update(mkSlotBgOverride(isActive))
  })
}


let tabsUi = @() {
  watch = shopItemsByGroups
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  children = shopItemsByGroups.value.map(@(v, idx) mkShopTab(v.locId, idx, groupIdx))
}



let headerUi = {
  size = [flex(), headerHeight]
  valign = ALIGN_CENTER
  children = [
    Bordered(loc("BackBtn"), @() isItemsShopOpened(false), {
      hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") }]]
    })
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      hplace = ALIGN_CENTER
      children = [
        currenciesWidgetUi
        armyCurrencyUi
      ]
    }
  ]
}


let function mkShopItemCard(idx, sItem, offers, army, tipGuid, isSuitable) {
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

    let clickCb = @() clickShopItem(sItem, level)
    let hoverCb = function(on) {
      if (hasNotifier)
        hoverHoldAction("markSeenShopItem", { guid, itemGuid },
          @(v) markShopItemSeen(v.guid, v.itemGuid))(on)
    }
    let alertText = isSuitable ? null : loc("shop/unsuitableForSoldier")

    let itemView = mkLowerShopItem(idx, guid, sItem, offer, content,
      templates, lockTxt, clickCb, hoverCb, alertText)
    return {
      watch = [crateContent, curUnseenAvailShopGuids, needFreemiumStatus, allItemTemplates]
      children = [
        itemView
        hasNotifier ? unblinkUnseen : null
        itemGuid == tipGuid ? tipObject : null
      ]
    }

  }
}


let function contentUi() {
  let army = curArmyData.value
  let offers = offersByShopItem.value
  let tipGuid = tipShopItemGuid.value
  let tipIdx = (shopItemsByGroups.value?[groupIdx.value].shopItems ?? [])
    .findindex(@(sItem) sItem.guid == tipGuid) ?? 0
  let suitable = curSuitableShopItems.value
  let content = (shopItemsByGroups.value?[groupIdx.value].shopItems ?? [])
    .map(function(sItem, idx) {
      let isSuitable = suitable?[sItem.guid] ?? false
      return mkShopItemCard(idx, sItem, offers, army, tipGuid, isSuitable)
    })
  return {
    watch = [groupIdx, shopItemsByGroups, curArmyData, offersByShopItem,
      tipShopItemGuid, curSuitableShopItems]
    size = [nestWidth, flex()]
    hplace = ALIGN_CENTER
    children = makeVertScroll({
      size = [nestWidth, SIZE_TO_CONTENT]
      children = wrap(content, {
        width = nestWidth
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
      scrollHandler
    })
    onAttach = function() {
      if (tipIdx > COLUMNS) {
        let scrollPos = (tipIdx / COLUMNS) * (lowerSlotSize[1] + columnGap) - smallPadding
        scrollHandler.scrollToY(scrollPos)
      }
    }
  }
}


let purchaseItemScene = @() {
  watch = safeAreaBorders
  key = "purchaseItemScene"
  size = flex()
  flow = FLOW_VERTICAL
  gap = smallPadding
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR
  color = 0xFFFFFFFF
  fillColor = 0xBB111417
  children = [
    headerUi
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = colPart(1)
      children = [
        tabsUi
        contentUi
      ]
    }
  ]
}


let function open() {
  sceneWithCameraAdd(purchaseItemScene, "items_inventory")
}

let function close() {
  sceneWithCameraRemove(purchaseItemScene)
}

isItemsShopOpened.subscribe(@(v) v ? open() : close())
if (isItemsShopOpened.value)
  open()


return function(armyId = null, templateId = null, itemTypes = []) {
  let shopItems = itemToShopItem.value?[armyId] ?? {}
  local tipGuid = armyId == null || templateId == null ? null : shopItems?[templateId][0]

  tipShopItemGuid(tipGuid)
  if (tipGuid == null) {
    let tplId = (allItemTemplates.value?[armyId] ?? {}).findindex(@(t, tpl)
      itemTypes.contains(t?.itemtype) && tpl in shopItems)
    if (tplId != null)
      tipGuid = shopItems[tplId]?[0]
  }
  if (tipGuid != null) {
    let idx = shopItemsByGroups.value.findindex(@(group)
      group.shopItems.findindex(@(i) i.guid == tipGuid) != null)
    if (idx != null)
      groupIdx(idx)
  }

  isItemsShopOpened(true)
}
