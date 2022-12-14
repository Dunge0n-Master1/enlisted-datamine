from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {round_by_value} = require("%sqstd/math.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { markSeenUpgrades, curUnseenAvailableUpgrades, isUpgradeUsed
} = require("model/unseenUpgrades.nut")
let { defTxtColor, textBgBlurColor, activeTxtColor, blurBgColor, blockedBgColor,
  blurBgFillColor, unitSize, bigPadding, smallPadding, tinyOffset
} = require("%enlSqGlob/ui/viewConst.nut")
let { show } = msgbox
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { Flat, PrimaryFlat, primaryButtonStyle } = require("%ui/components/textButton.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { statusIconCtor } = require("%enlSqGlob/ui/itemPkg.nut")
let { mkItemDemands, mkItemListDemands } = require("model/mkItemDemands.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { itemTypesInSlots } = require("model/all_items_templates.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { mkDetailsInfo, lockedInfo } = require("components/itemDetailsComp.nut")
let { blur } = require("%enlist/soldiers/components/itemDetailsPkg.nut")
let { curUpgradeDiscount, campPresentation } = require("%enlist/campaigns/campaignConfig.nut")
let { setTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let spinner = require("%ui/components/spinner.nut")({height = hdpx(50)})
let mkHeader = require("%enlist/components/mkHeader.nut")
let mkToggleHeader = require("%enlist/components/mkToggleHeader.nut")

let defcomps= require("%enlSqGlob/ui/defcomps.nut")
let mkItemWithMods = require("mkItemWithMods.nut")
let mkSoldierInfo = require("mkSoldierInfo.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")
let { getSoldierItemSlots, getEquippedItemGuid, curArmyData
} = require("%enlist/soldiers/model/state.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { isItemActionInProgress } = require("model/itemActions.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { curHoveredItem } = require("%enlist/showState.nut")
let { focusResearch, findResearchUpgradeUnlock, findResearchSlotUnlock
} = require("%enlist/researches/researchesFocus.nut")
let { unequipItem, unequipBySlot } = require("%enlist/soldiers/unequipItem.nut")
let { slotItems, otherSlotItems, prevItems, selectParams, curEquippedItem,
  viewItem, viewSoldierInfo, paramsForPrevItems,
  openSelectItem, trySelectNext, curInventoryItem, checkSelectItem, selectItem, itemClear,
  selectNextSlot, selectPreviousSlot, unseenViewSlotTpls, viewItemMoveVariants, ItemCheckResult
} = require("model/selectItemState.nut")
let { markWeaponrySeen } = require("model/unseenWeaponry.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { openUpgradeItemMsg, openDisposeItemMsg } = require("components/modifyItemComp.nut")
let itemTransferMsg = require("%enlist/items/itemTransferMsg.nut")
let { scrollToCampaignLvl } = require("model/armyUnlocksState.nut")
let { mkItemUpgradeData, mkItemDisposeData } = require("model/mkItemModifyData.nut")
let gotoResearchUpgradeMsgBox = require("researchUpgradeMsgBox.nut")
let { justPurchasedItems } = require("model/newItemsToShow.nut")
let { getShopItemsCmp } = require("%enlist/shop/armyShopState.nut")
let { mkOnlinePersistentFlag } = require("%enlist/options/mkOnlinePersistentFlag.nut")
let openArmoryTutorial = require("%enlist/tutorial/armoryTutorial.nut")
let isNewbie = require("%enlist/unlocks/isNewbie.nut")
let { isItemTransferEnabled } = require("%enlist/featureFlags.nut")
let itemsTransferConfig = require("model/config/itemsTransferConfig.nut")
local { isDetailsFull, detailsModeCheckbox } = require("%enlist/items/detailsMode.nut")
let { isObjGuidBelongToRentedSquad } = require("%enlist/soldiers/model/squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")
let clickShopItem = require("%enlist/shop/clickShopItem.nut")


let armoryWndOpenFlag = mkOnlinePersistentFlag("armoryWndOpenFlag")
let armoryWndHasBeenOpend = armoryWndOpenFlag.flag
let markSeenArmoryTutorial = armoryWndOpenFlag.activate

let getItemSelectKey = @(item) item?.isShopItem ? item?.basetpl : item?.guid

let selectedKey = Watched(null)
viewItem.subscribe(function(item) { selectedKey(getItemSelectKey(item)) })

let selectedSlot = Computed(function() {
  let { ownerGuid = "", slotType = "", slotId = "" } = selectParams.value
  local guid
  if (ownerGuid != "" && slotType != "")
    guid = getEquippedItemGuid(campItemsByLink.value, ownerGuid, slotType, slotId)
  return guid ?? "_".concat(ownerGuid, slotType, slotId)
})

let defStatusCtor = function(item, soldierWatch) {
  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.value)
  }
}

let function txt(text) {
  let children = (type(text) == "string")
    ? defcomps.txt({text}.__update(sub_txt))
    : defcomps.txt(text)
  return blur({ children })
}

let activeItemParams = {
  statusCtor = defStatusCtor
}

let blockedItemParams = {
  bgColor = blockedBgColor
  statusCtor = defStatusCtor
  canEquip = false
  onDoubleClickCb = null
}

let prevItemParams = {
  statusCtor = defStatusCtor
  selectedKey = selectedSlot
  onClickCb = function(data) {
    let prev = paramsForPrevItems.value
    let { soldierGuid = "" } = data
    if (soldierGuid != "") //data.item is item mod
      openSelectItem({
        armyId = prev?.armyId
        ownerGuid = soldierGuid
        slotType = data.slotType
        slotId = data.slotId
      })
    else
      curInventoryItem(data.item)
  }
  canEquip = false
  onDoubleClickCb = unequipItem
}

let function showMessage(item, checkInfo) {
  let { result, soldier = null, slotType = null, soldierClass = null, level = null } = checkInfo
  let buttons = [{ text = loc("Ok"), isCancel = true }]
  local text = ""
  if (result == ItemCheckResult.NEED_RESEARCH){
    text = loc("slotClassResearch", { soldierClass })
    buttons.append({
      text = loc("GoToResearch")
      action = function() {
        focusResearch(findResearchSlotUnlock(soldier, slotType))
      }
      isCurrent = true })

  } else if (result == ItemCheckResult.WRONG_CLASS){
    text = loc("Not available for class", { soldierClass })

  } else if (result == ItemCheckResult.NEED_LEVEL){
    text = loc("obtainAtLevel", { level })
    buttons.append({
      text = loc("GoToArmyLeveling")
      action = function() {
        scrollToCampaignLvl(level)
        jumpToArmyProgress()
      }
      isCurrent = true })

  } else if (result == ItemCheckResult.IN_SHOP) {
    let shopItemsCmp = getShopItemsCmp(item.basetpl)
    if (shopItemsCmp.value.len() > 0){
      text = loc("shop/dontHaveItem", {item = loc(shopItemsCmp.value[0].nameLocId)})
      buttons.append({
        text = loc("btn/buy")
        action = function() {
          clickShopItem(shopItemsCmp.value[0], curArmyData.value?.level ?? 0)
        }
        isCurrent = true })
    }
  }
  msgbox.show({ text, buttons })
}

let mkDropExceptionCb = @(currentItem) function(dropItem) {
  let checkCurrentItem = checkSelectItem(currentItem)
  if (checkCurrentItem) {
    showMessage(currentItem, checkCurrentItem)
    return
  }
  let checkDropItem = checkSelectItem(dropItem)
  if (checkDropItem)
    showMessage(dropItem, checkDropItem)
}

let mkStdCtorData = @(size) {
  size = size
  itemsInRow = 1
  ctor = @(item, override) mkItemWithMods({
    isXmb = true
    item = item
    itemSize = size
    canDrag = !!item?.basetpl
    selectedKey = selectedKey
    selectKey = getItemSelectKey(item)
    onClickCb = @(data) data.item == item ? curInventoryItem(item)
      : (item?.guid ?? "") != "" ? openSelectItem({ // data.item is mod of item
          armyId = selectParams.value?.armyId
          ownerGuid = item.guid
          slotType = data.slotType
          slotId = data.slotId
        })
      : null
    onDropExceptionCb = mkDropExceptionCb(item)
    onDoubleClickCb = function(data) {
      if (data.item != item)
        return
      let checkSelectInfo = checkSelectItem(item)
      if (checkSelectInfo){
        showMessage(item, checkSelectInfo)
        return
      }
      selectItem(item)
      trySelectNext()
    }
  }.__update(override))
}

let defaultCtorData = mkStdCtorData([3.0 * unitSize, 2.0 * unitSize]).__update({ itemsInRow = 2 })
let mainWeaponCtorData = mkStdCtorData([7.0 * unitSize, 2.0 * unitSize])

let getCtorData = @(typesInSlots, itemType)
  itemType in typesInSlots.mainWeapon ? mainWeaponCtorData : defaultCtorData

let mkItemsList = @(listWatch, itemParamsOverride) function() {
  itemParamsOverride.soldierGuid <- viewSoldierInfo.value?.guid
  let items = listWatch.value
  let ctorData = getCtorData(itemTypesInSlots.value, items?[0].itemtype)
  let { size, itemsInRow } = ctorData
  let itemContainerWidth = itemsInRow * size[0] + (itemsInRow - 1) * bigPadding
  return wrap(
    items.map(@(item) (getCtorData(itemTypesInSlots.value, item?.itemtype) ?? ctorData).ctor(item, itemParamsOverride)),
    { width = itemContainerWidth, hGap = smallPadding, vGap = smallPadding, hplace = ALIGN_CENTER }
  ).__update({ watch = [listWatch, itemTypesInSlots, viewSoldierInfo] })
}

let sortDemandsOrder = @(d) d?.canObtainInShop == true ? 2000
  : d?.classLimit != null ? 1500
  : "levelLimit" in d ? 1000 - d.levelLimit
  : 0

let function sortByDemands(a, b) {
  return (b == "") <=> (a == "")
    || sortDemandsOrder(b) <=> sortDemandsOrder(a)
}

let function mkDemandHeader(demand) {
  let key = demand.keys()?[0]
  let value = demand?[key]
  let suffix = value == true ? "_yes"
    : value == false ? "_no"
    : ""
  return {
    rendObj = ROBJ_TEXT
    size = [flex(), SIZE_TO_CONTENT]
    margin = [tinyOffset, 0, 0, 0]
    text = loc($"itemDemandsHeader/{key}{suffix}", demand)
    color = defTxtColor
  }.__update(sub_txt)
}

let mkItemsGroupedList = kwarg(@(listWatch, overrideParams, newWatch, onlyNew = false)
  function() {
    overrideParams.soldierGuid <- viewSoldierInfo.value?.guid

    let newList = newWatch.value
    let itemsToDisplay = listWatch.value
      .filter(@(i) !onlyNew || newList.contains(i.guid))

    let itemsWithDemands = mkItemListDemands(itemsToDisplay)
    let itemsDemands = itemsWithDemands.value
    let ctorData = getCtorData(itemTypesInSlots.value, itemsDemands?[0].item.itemtype)
    let { size, itemsInRow } = ctorData
    let itemContainerWidth = itemsInRow * size[0] + (itemsInRow - 1) * bigPadding

    let groupedItems = {}
    foreach (data in itemsDemands) {
      let { item, demands = "" } = data
      groupedItems[demands] <- (groupedItems?[demands] ?? []).append(item)
    }
    let children = []
    let demandsOrdered = groupedItems.keys().sort(sortByDemands)
    foreach (demand in demandsOrdered) {
      if (demand != "")
        children.append(mkDemandHeader(demand))

      let itemsList = groupedItems[demand].map(function(item) {
          let ctor = (getCtorData(itemTypesInSlots.value, item?.itemtype) ?? ctorData).ctor
          let { basetpl = "" } = item
          let isUnseen = Computed(@() basetpl in unseenViewSlotTpls.value
            || (!isUpgradeUsed.value && basetpl in curUnseenAvailableUpgrades.value))
          return ctor(item,
            overrideParams.__merge({
              isNew = onlyNew
              hasUnseenSign = isUnseen
              onHoverCb = hoverHoldAction("unseenSoldierItem", basetpl,
                function(tpl) {
                  let { armyId = null } = selectParams.value
                  if (isUnseen.value && armyId != null)
                    markWeaponrySeen(armyId, tpl)
                })
            }))
        })

      children.append(wrap(itemsList, {
        width = itemContainerWidth, hGap = smallPadding, vGap = smallPadding, hplace = ALIGN_CENTER
      }))
    }
    return {
      watch = [listWatch, itemTypesInSlots, viewSoldierInfo, itemsWithDemands]
      size = [itemContainerWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = children
    }
  })

let armoryList = mkItemsGroupedList({
  listWatch = slotItems
  overrideParams = activeItemParams
  newWatch = justPurchasedItems
})
let otherList = mkItemsGroupedList({
  listWatch = otherSlotItems
  overrideParams = blockedItemParams
  newWatch = justPurchasedItems
})
let otherListNewOnly = mkItemsGroupedList({
  listWatch = otherSlotItems
  overrideParams = blockedItemParams
  newWatch = justPurchasedItems
  onlyNew = true
})

let prevArmory = mkItemsList(prevItems, prevItemParams)

let backButton = Flat(loc("mainmenu/btnBack"), itemClear,
  { margin = [0, bigPadding, 0, 0] })

let chooseButtonUi = function() {
  let item = viewItem.value
  let equippedItem = curEquippedItem.value
  let isCheckFail = checkSelectItem(item) != null
  let buttonParam = { margin = [0, bigPadding, 0, 0], hotkeys = [[ "^J:Y" ]] }
  let button =  @(params) Flat(loc("mainmenu/btnSelect"), @() selectItem(item), params)

  return {
    watch = [viewItem, curEquippedItem]
    children = item == equippedItem || (equippedItem == null && item?.basetpl == null)
        ? null
      : isCheckFail ? button(buttonParam)
      : button(buttonParam.__merge(primaryButtonStyle,  body_txt))
  }
}


let function mkObtainButton(item) {
  if (item == null)
    return null

  let demands = mkItemDemands(item).value
  let { levelLimit = null } = demands
  let shopItemsCmp = getShopItemsCmp(item.basetpl)

  return levelLimit != null ? Flat(loc("GoToArmyLeveling"),
      function() {
        scrollToCampaignLvl(item.unlocklevel)
        jumpToArmyProgress()
      },
      { margin = [0, bigPadding, 0, 0] })
    : shopItemsCmp.value.len() > 0 ? Flat(loc("btn/buy"),
      @() clickShopItem(shopItemsCmp.value[0], curArmyData.value?.level ?? 0),
        { margin = [0, bigPadding, 0, 0], hotkeys = [["^J:X"]] })
    : null
}

let function obtainButtonUi() {
  let item = viewItem.value

  return {
    watch = [viewItem, viewSoldierInfo]
    children = mkObtainButton(item)
  }
}

let mkListToggleHeader = @(sClass, flag) mkToggleHeader(flag
  loc("Not available for class", { soldierClass = loc(soldierClasses?[sClass].locId ?? "unknown") }))

let function otherItemsBlock() {
  let res = { watch = [viewSoldierInfo, otherSlotItems] }
  if (otherSlotItems.value.len() == 0)
    return res

  let isListExpanded = Watched(false)
  let sClass = viewSoldierInfo.value?.sClass ?? "unknown"
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkListToggleHeader(sClass, isListExpanded)
      @() {
        watch = isListExpanded
        children = isListExpanded.value ? otherList : otherListNewOnly
      }
    ]
  })
}

let mkItemsListBlock = @(children) {
  size = [SIZE_TO_CONTENT, flex()]
  padding = [bigPadding, bigPadding]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  behavior = [Behaviors.DragAndDrop]
  xmbNode = XmbContainer({
    canFocus = @() false
    scrollSpeed = 5.0
    isViewport = true
  })
  children = makeVertScroll(children, {
    size = [SIZE_TO_CONTENT, flex()]
    needReservePlace = false
  })
  canDrop = @(data) data?.slotType != null
  onDrop = @(data) unequipItem(data)
}

let itemsListBlock = @() {
  size = [SIZE_TO_CONTENT, flex()]
  watch = [slotItems, otherSlotItems]
  children = slotItems.value.len() > 0 || otherSlotItems.value.len() > 0
    ? mkItemsListBlock({
        flow = FLOW_VERTICAL
        children = [
          armoryList
          otherItemsBlock
        ]
      })
    : null
}

let prevItemsListBlock = @() {
  size = [SIZE_TO_CONTENT, flex()]
  watch = prevItems
  children = prevItems.value.len()
    ? mkItemsListBlock(prevArmory)
    : null
}

let openResearchUpgradeMsgbox = function(item, armyId) {
  let research = findResearchUpgradeUnlock(armyId, item)
  if (research == null)
    show({
      text = loc("itemUpgradeNoSquad")
      buttons = [
        {
          text = loc("squads/gotoUnlockBtn")
          action = jumpToArmyProgress
          isCurrent = true
        }
        { text = loc("Ok"), isCancel = true }
      ]
    })
  else
    show({
      text = loc("itemUpgradeResearch")
      buttons = [
        {
          text = loc("mainmenu/btnResearch")
          action = function() {
            focusResearch(research)
          }
          isCurrent = true
        }
        { text = loc("Ok"), isCancel = true }
      ]
    })
}

let function mkUpgradeBtn(item) {
  let upgradeDataWatch = mkItemUpgradeData(item)
  return function() {
    let res = {
      watch = [upgradeDataWatch, curUnseenAvailableUpgrades, isUpgradeUsed,
        curUpgradeDiscount, campPresentation]
    }
    let upgradeData = upgradeDataWatch.value
    if (!upgradeData.isUpgradable)
      return res

    res.margin <- [0, bigPadding, 0, 0]
    let { isResearchRequired, armyId, hasEnoughOrders, upgradeMult, itemBaseTpl } = upgradeData

    if (isResearchRequired)
      return res.__update({
        children = Flat(loc("btn/upgrade"), @() openResearchUpgradeMsgbox(item, armyId), {
          margin = 0
          cursor = normalTooltipTop
          onHover = @(on) setTooltip(on ? loc("tip/btnUpgrade") : null)
        })
      })

    let bCtor = hasEnoughOrders ? PrimaryFlat : Flat
    let discount = round_by_value(100 - upgradeMult * 100, 1).tointeger()
    let upgradeMultInfo = discount <= 0 ? null : txt({
      text = loc("upgradeDiscount", { discount })
      color = activeTxtColor
    }).__update(curUpgradeDiscount.value > 0.0 ? {
      rendObj = ROBJ_SOLID
      color = campPresentation.value?.darkColor
    } : {})
    return res.__update({
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        upgradeMultInfo
        {
          children = [
            bCtor(loc("btn/upgrade"),
              function() {
                if (isObjGuidBelongToRentedSquad(item?.guid))
                  showRentedSquadLimitsBox()
                else
                  openUpgradeItemMsg(item, upgradeData)
              },
              {
                margin = 0
                cursor = normalTooltipTop
                onHover = function(on) {
                  if (!isUpgradeUsed.value && item?.basetpl in curUnseenAvailableUpgrades.value)
                    hoverHoldAction("unseenUpdate", itemBaseTpl,
                      @(tpl) markSeenUpgrades(selectParams.value?.armyId, [tpl]))(on)
                  setTooltip(on ? loc("tip/btnUpgrade") : null)
                }
              })
            !isUpgradeUsed.value && item?.basetpl in curUnseenAvailableUpgrades.value
              ? unseenSignal(0.8).__update({ hplace = ALIGN_RIGHT })
              : null
          ]
        }
      ]
    })
  }
}

let upgradeBtnUi = @() {
  watch = viewItem
  children = mkUpgradeBtn(viewItem.value)
}

let function mkDisposeBtn(item) {
  let disposeDataWatch = mkItemDisposeData(item)
  return function() {
    let res = { watch = [disposeDataWatch] }
    let disposeData = disposeDataWatch.value
    if (!disposeData.isDisposable)
      return res

    res.margin <- [0, bigPadding, 0, 0]
    let { disposeMult, isDestructible = false, isRecyclable = false } = disposeData

    let bCtor = Flat
    let bonus = round_by_value(disposeMult * 100 - 100, 1).tointeger()
    let disposeMultInfo = bonus <= 0 ? null : txt({
      text = loc("disposeBonus", { bonus })
      color = activeTxtColor
    })
    return res.__update({
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        disposeMultInfo
        bCtor(loc(isRecyclable ? "btn/recycle" : isDestructible ? "btn/dispose" : "btn/downgrade"),
          @() openDisposeItemMsg(item, disposeData), {
            margin = 0
            cursor = normalTooltipTop
            onHover = @(on)
              setTooltip(on ? loc(isRecyclable ? "tip/btnRecycle"
                  : isDestructible ? "tip/btnDispose"
                  : "tip/btnDowngrade")
                : null)
          })
      ]
    })
  }
}

let disposeBtnUi = @() {
  watch = viewItem
  children = mkDisposeBtn(viewItem.value)
}

let function moveButtonUi() {
  let { availableTypes = [], requiredOrders = [] } = itemsTransferConfig.value
  let item = viewItem.value
  let res = {
    watch = [ viewItem, curEquippedItem, viewItemMoveVariants, isItemTransferEnabled, itemsTransferConfig ]
  }
  if (item == null)
    return res
  let equipItem = curEquippedItem.value
  let isMovable = availableTypes.contains(item.itemtype)
  if (!isItemTransferEnabled.value // TODO: need to delete after item transfer will enabled
      || !isMovable
      || item == equipItem
      || viewItemMoveVariants.value.len() == 0)
    return res

  return res.__update({
    children = Flat(loc("btn/moveItemToArmy"),
      @() itemTransferMsg(item, viewItemMoveVariants, requiredOrders),
      { margin = [0, bigPadding, 0, 0] })
  })
}

let buttonsUi = @() {
  watch = [isItemActionInProgress, isGamepad]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
  flow = FLOW_HORIZONTAL
  padding = [bigPadding, 0, bigPadding, bigPadding]
  valign = ALIGN_BOTTOM
  children = [isGamepad.value ? null : backButton]
    .extend(isItemActionInProgress.value
      ? [spinner]
      : [moveButtonUi, obtainButtonUi, upgradeBtnUi, disposeBtnUi, chooseButtonUi])
}

let function mkDemandsInfo(item) {
  if (item == null)
    return null

  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = demandsWatch
    size = [flex(), SIZE_TO_CONTENT]
    padding = smallPadding
    children = lockedInfo(demandsWatch.value)
  }
}


let infoBlock = @() {
  watch = viewItem
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  gap = bigPadding
  children = [
    mkDetailsInfo(viewItem, isDetailsFull)
    mkDemandsInfo(viewItem.value)
    detailsModeCheckbox
    buttonsUi
  ]
}


let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[-hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [-hdpx(150), 0], duration = 0.2, easing = OutQuad }
]

let function getItemSlot(item, soldier) {
  if (!item || !soldier)
    return null
  let ownerGuid = soldier.guid
  let itemSlot = getSoldierItemSlots(ownerGuid, campItemsByLink.value)
    .findvalue(@(slot) slot.item?.guid == item?.guid)
  if (!itemSlot)
    return null
  local { slotType, slotId } = itemSlot
  if (slotId == null) {
    let equipScheme = soldier?.equipScheme ?? {}
    slotId = slotType
    slotType = equipScheme.findindex(@(val) slotType in val)
    if (slotType == null)
      return null
  }
  return {
    ownerGuid = ownerGuid
    slotType = slotType
    slotId = slotId
  }
}

let quickEquipHotkeys = function() {
  let item = curHoveredItem.value
  let res = { watch = [isGamepad, curHoveredItem] }
  if (!isGamepad.value || item == null)
    return res

  let soldier = viewSoldierInfo.value
  let slot = getItemSlot(item, soldier)
  return slot != null
    // quick uneqip
    ? res.__update({
        children = {
          key = $"unequip_{item?.guid}"
          hotkeys = [["^J:Y", {
            description = loc("equip/quickUnequip")
            action = function() {
              unequipBySlot(slot)
              openSelectItem(slot.__merge({ armyId = selectParams.value?.armyId }))
            }
          }]]
        }
      })
    // quick equip
    : res.__update({
        children = {
          key = $"equip_{item?.guid}"
          hotkeys = [["^J:Y", {
            description = loc("equip/quickEquip")
            action = function() {
              let checkSelectInfo = checkSelectItem(item)
              if (checkSelectInfo){
                showMessage(item, checkSelectInfo)
                return
              }
              selectItem(item)
            }
          }]]
        }
      })
}

let itemsContent = [
  {
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    animations = animations
    transform = {}
    children = [
      mkSoldierInfo({
        soldierInfoWatch = viewSoldierInfo
        isMoveRight = false
        selectedKeyWatch = selectedSlot
        onDoubleClickCb = unequipItem
        getDropExceptionCb = mkDropExceptionCb
        onResearchClickCb = gotoResearchUpgradeMsgBox
        availTabs = ["weaponry"]
      })
      prevItemsListBlock
      itemsListBlock
      {
        size = flex()
        valign = ALIGN_BOTTOM
        halign = ALIGN_RIGHT
        children = infoBlock
        behavior = Behaviors.DragAndDrop
        onDrop = @(data) unequipItem(data)
        canDrop = @(data) data?.slotType != null
        skipDirPadNav = true
      }
    ]
    hotkeys = [
      ["^Tab | J:RB", { action = selectNextSlot, description = loc("equip/nextSlot") }],
      ["^L.Shift Tab | R.Shift Tab | J:LB", { action = selectPreviousSlot, description = loc("equip/prevSlot") }]
    ]
  }
  quickEquipHotkeys
]

let selectItemScene = @() {
  watch = safeAreaBorders
  size = [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  key = "selectItemScene"
  onAttach = function(){
    if (armoryWndHasBeenOpend.value && isNewbie.value){
      openArmoryTutorial()
      markSeenArmoryTutorial()
    }
  }
  padding = safeAreaBorders.value
  behavior = Behaviors.MenuCameraControl
  children = [
    @() {
      size = [flex(), SIZE_TO_CONTENT]
      watch = selectParams
      children = mkHeader({
        armyId = selectParams.value?.armyId
        textLocId = "Choose item"
        closeButton = closeBtnBase({ onClick = itemClear })
      })
    }
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = itemsContent
    }
  ]
}

let function open() {
  sceneWithCameraAdd(selectItemScene, "armory")
}

if (selectParams.value)
  open()

selectParams.subscribe(function(p) {
  if (p == null)
    sceneWithCameraRemove(selectItemScene)
  else
    open()
})
