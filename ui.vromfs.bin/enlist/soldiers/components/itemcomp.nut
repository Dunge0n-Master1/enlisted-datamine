from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { unitSize, gap, bigGap, bigPadding, smallPadding, soldierWndWidth, fadedTxtColor,
  defBgColor, defTxtColor, blockedBgColor, listCtors
} = require("%enlSqGlob/ui/viewConst.nut")
let listTxtColor = listCtors.txtColor
let listBgColor = listCtors.bgColor
let { statusIconCtor, statusIconLocked, statusBadgeWarning
} = require("%enlSqGlob/ui/itemPkg.nut")
let { mkItemDemands } = require("%enlist/soldiers/model/mkItemDemands.nut")
let { objInfoByGuid, getItemOwnerGuid, getSoldierItemSlots, getItemIndex,
  getDemandingSlots, getDemandingSlotsInfo, getEquippedItemGuid
} = require("%enlist/soldiers/model/state.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { equipItem, swapItems } = require("%enlist/soldiers/model/itemActions.nut")
let { iconByItem, getItemName, getItemDesc, trimUpgradeSuffix
} = require("%enlSqGlob/ui/itemsInfo.nut")
let { curHoveredItem } = require("%enlist/showState.nut")
let popupsState = require("%enlist/popup/popupsState.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let cursors = require("%ui/style/cursors.nut")
let { unequipItem } = require("%enlist/soldiers/unequipItem.nut")
let { sound_play } = require("sound")
let { mkItemUpgradeData } = require("%enlist/soldiers/model/mkItemModifyData.nut")
let mkAmmo = require("mkAmmo.nut")
let { getWeaponData } = require("%enlist/soldiers/model/collectWeaponData.nut")
let { mkSpecialItemIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { isObjGuidBelongToRentedSquad } = require("%enlist/soldiers/model/squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")
let { mkAlertIcon, ITEM_ALERT_SIGN } = require("%enlSqGlob/ui/soldiersUiComps.nut")


let DISABLED_ITEM = { tint = Color(40, 40, 40, 160), picSaturate = 0.0 }

let defItemSize = [soldierWndWidth - bigPadding * 2, unitSize * 2]

let itemDragData = Watched()

let smallMainColorText = function(text, sf, selected) {
  let res = {
    rendObj = ROBJ_TEXT
    vplace = ALIGN_BOTTOM
    color = listTxtColor(sf, selected)
    text
  }.__update(sub_txt)
  if (!(selected || (sf & S_HOVER)))
    res.__update({
      fontFx = FFT_SHADOW
      fontFxColor = 0xFF000000
      fontFxFactor = hdpx(16)
      fontFxOffsX = hdpx(1)
      fontFxOffsY = hdpx(1)
    })
  return res
}

let amountText = @(count, sf, selected) {
  rendObj = ROBJ_SOLID
  color = selected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_TEXT
    color = listTxtColor(sf, selected)
    text = loc("common/amountShort", { count })
  }.__update(sub_txt)
}

let defSlotnameCtor = @(slotType, _itemSize, isSelected, flags, group) slotType == null ? null : {
  rendObj = ROBJ_TEXT
  group = group
  margin = smallPadding
  hplace = ALIGN_RIGHT
  color = listTxtColor(flags, isSelected)
  text = loc($"inventory/{slotType}", "")
  opacity = 0.5
}.__update(tiny_txt)

let nameBlockCtor = @(item, sf, selected, group, ammoBox = null) {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  padding = bigPadding
  gap = hdpx(2)
  flow = FLOW_HORIZONTAL
  children = [
    itemTypeIcon(item?.itemtype, item?.itemsubtype, { tint = listTxtColor(sf, selected) })
    mkSpecialItemIcon(item)
    {
      size = [flex(), SIZE_TO_CONTENT]
      clipChildren = true
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        group = group
        behavior = Behaviors.Marquee
        scrollOnHover = true
        children = smallMainColorText(getItemName(item), sf, selected)
      }
    }
    ammoBox
  ]
}

let defItemCtor = function(
  item, _slotType, itemSize, isSelected, flags, group, isAvailable = false, ammoBox = null) {
  let isWide = (itemSize?[0] ?? 1) / (itemSize?[1] ?? 1) < 2
  let iconParams = {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    width = isWide
      ? itemSize[0] - 2 * smallPadding
      : itemSize[1] * 3 - 2 * bigPadding
    height = isWide
      ? itemSize[1] - 2 * smallPadding
      : itemSize[1] - 2 * bigPadding
  }.__update(isAvailable ? {} : DISABLED_ITEM)
  let itemName = nameBlockCtor(item, flags, isSelected, group, ammoBox)
  let itemIcon = iconByItem(item, iconParams)
  return {
    size = flex()
    children = [
      itemIcon
      itemName
    ]
  }
}

let defAmountCtor = @(item, sf, selected) (item?.count ?? 1) > 1
  ? amountText(item.count, sf, selected)
  : null

let canEquip = @(item, scheme) item != null && !(item?.isShopItem ?? false)
  && (scheme == null
    || ((scheme?.itemTypes.len() ?? 0) == 0 && (scheme?.items.len() ?? 0) == 0)
    || scheme?.itemTypes.indexof(item?.itemtype) != null
    || scheme?.items.indexof(trimUpgradeSuffix(item?.basetpl)) != null)

let showSwapImpossible = @(text) popupsState.addPopup({
  id = "swap_items_error"
  text
  styleName = "error"
})

let function checkFixedItem(item) {
  if (item?.isFixed ?? false) {
    showSwapImpossible(loc($"equipDemand/deniedUnequipPremium"))
    return true
  }
  return false
}

// targetDropData is the data of a slot, WHERE we drop an item
// draggedDropData is the data of a slot, FROM where drag originated
let function trySwapItems(toOwnerGuid, targetDropData, draggedDropData) {
  if (draggedDropData == null)
    return false

  local { slotId = null, slotType = null, item = {} } = targetDropData?.slotType == null ? targetDropData : draggedDropData
  if (checkFixedItem(item))
    return false

  let toSlotType = targetDropData?.slotType ?? draggedDropData.slotType
  let toSlotId = targetDropData?.slotId ?? draggedDropData.slotId
  let itemGuid = item?.guid
  if (!toOwnerGuid || !itemGuid)
    return false

  let equippedItems = getSoldierItemSlots(toOwnerGuid, campItemsByLink.value)
  let toItem = equippedItems.findvalue(@(d) d.slotType == toSlotType && d.slotId == toSlotId)?.item
  if (checkFixedItem(toItem))
    return false

  // dropping item from the soldier's card into storage:
  if (targetDropData.scheme == null){
    // dropping item into empty storage slot, unequip:
    if ("guid" not in targetDropData.item){
      unequipItem(draggedDropData)
      return false
    }
    if (isObjGuidBelongToRentedSquad(toOwnerGuid)) {
      showRentedSquadLimitsBox()
      return false
    }
    // equip item from target storage slot:
    equipItem(targetDropData.item.guid, draggedDropData.slotType, draggedDropData.slotId, toOwnerGuid)
    return true
  }

  // dropping item
  let parentItemGuid = getItemOwnerGuid(item)
  if (!parentItemGuid) {
    // equip from inventory
    if (isObjGuidBelongToRentedSquad(toOwnerGuid)) {
      showRentedSquadLimitsBox()
      return false
    }
    equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
    return true
  }

  slotId = slotId ?? getItemIndex(item)
  slotType = slotType ?? item.links[parentItemGuid]

  // swap already equipped
  let owner = objInfoByGuid.value?[parentItemGuid]
  let demandingSlots = getDemandingSlots(parentItemGuid, slotType, owner, campItemsByLink.value)
  if (demandingSlots.len() > 0) {
    local equippedCount = demandingSlots.filter(@(v) v != null).len()
    let equippedGuid = getEquippedItemGuid(campItemsByLink.value, toOwnerGuid, toSlotType, toSlotId)
    if (!equippedGuid && !(toSlotId in demandingSlots))
      --equippedCount
    if (equippedCount < 1) {
      if (draggedDropData.scheme?.atLeastOne == targetDropData.scheme?.atLeastOne) {
        equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
        return true
      }
      let demandingInfo = getDemandingSlotsInfo(parentItemGuid, slotType)
      if (demandingInfo != "") {
        showSwapImpossible(demandingInfo)
        return false
      }
    }
  }

  if (toItem != null)
    swapItems(toOwnerGuid, toSlotType, toSlotId, parentItemGuid, slotType, slotId)
  else {
    if (isObjGuidBelongToRentedSquad(toOwnerGuid)) {
      showRentedSquadLimitsBox()
      return false
    }
    equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
  }

  return true
}

let hintWithIcon = @(icon, locId) {
  flow = FLOW_HORIZONTAL
  gap = gap
  valign = ALIGN_CENTER
  children = [
    faComp(icon, {fontSize = hdpx(12), color = fadedTxtColor})
    {
      rendObj = ROBJ_TEXT
      text = loc(locId)
      color = fadedTxtColor
    }.__update(tiny_txt)
  ]
}

let dragAndDropHint = hintWithIcon("hand-paper-o", "hint/equipDragAndDrop")
let quickEquipHint = hintWithIcon("reply", "hint/equipDoubleClick")
let quickUnequipHint = hintWithIcon("share", "hint/unequipDoubleClick")

let function makeToolTip(item, canDrag, isEquipped, canChange) {
  if (!item?.gametemplate)
    return null

  let hints = []
  if (!isGamepad.value && item?.guid && !(item?.isShopItem ?? false)) {
    if (canDrag)
      hints.append(dragAndDropHint)
    if (canChange)
      hints.append(isEquipped ? quickUnequipHint : quickEquipHint)
  }
  let desc = getItemDesc(item)
  return tooltipBox(@() {
    watch = isGamepad
    minWidth = hdpx(350)
    maxWidth = hdpx(500)
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = getItemName(item)
            color = defTxtColor
          }.__update(body_txt)
          detailsStatusTier(item)
        ]
      }
      desc == "" ? null : {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpx(500)
        text = desc
        color = Color(180, 180, 180, 120)
      }
      hints.len() <= 0 ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        minWidth = SIZE_TO_CONTENT
        color = Color(0, 0, 0, 224)
        flow = FLOW_VERTICAL
        margin = [bigGap, 0, 0, 0]
        gap = bigGap
        children = hints
      }
    ]
  })
}

let defBgStyle = @(sf, selected) { rendObj = ROBJ_SOLID, color = listBgColor(sf, selected) }
let function defIconCtor(item, soldierWatch) {
  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.value)
  }
}

let itemCountRarity = @(item, flags, isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = [
    detailsStatusTier(item)
    defAmountCtor(item, flags, isSelected)
  ]
}

let mkUnseenSign = @(hasUnseenSign) mkAlertIcon(ITEM_ALERT_SIGN, hasUnseenSign)

let mkUpgradableSign = @(sf, selected) faComp("gear", {
  size = [hdpx(20), hdpx(20)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fontSize = hdpx(15)
  color = listTxtColor(sf, selected)
})

let newSign = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_RIGHT
  padding = [0, smallPadding]
  color = Color(255,255,100)
  text = loc("item/recentlyReceived")
  animations = [{
    prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1,
    play = true, loop = true, easing = Blink
  }]
}.__update(sub_txt)

let mkSigns = @(upgradeData, sf, selected, isNew) @() {
  watch = upgradeData
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  size = [SIZE_TO_CONTENT, flex()]
  children = [
    upgradeData.value.isUpgradable ? mkUpgradableSign(sf, selected) : null
    isNew ? newSign : null
  ]
}

local function mkItem(slotId = null, item = null, slotType = null, itemSize = defItemSize,
  emptySlotChildren = defSlotnameCtor, scheme = null, itemCtor = defItemCtor,
  onDropExceptionCb = null, statusCtor = defIconCtor, soldierGuid = null, isInteractive = true,
  isDisabled = false, canDrag = true, bgStyle = defBgStyle, selectedKey = Watched(null),
  selectKey = null, isXmb = false, bgColor = defBgColor, pauseTooltip = Watched(false),
  onClickCb = null, onHoverCb = null, isLocked = false, onDoubleClickCb = null,
  onResearchClickCb = null, mods = null, hasUnseenSign = Watched(false), isNew = false,
  isAvailable = null, hideStatus = false, hasWarningSign = false
) {
  if (isDisabled)
    isInteractive = false

  let soldier = Computed(@() objInfoByGuid.value?[soldierGuid])
  if (type(item) == "string")
    item = objInfoByGuid.value?[item]
  let itemDesc = { item, slotType, soldierGuid, slotId, scheme }

  let weapData = getWeaponData(item?.gametemplate ?? "")
  let needShowAmmo = weapData?["caliber"] != null || weapData?["bullets"] != null
  let ammoBox = needShowAmmo ? mkAmmo(item, soldierGuid, weapData, slotType) : null

  let stateFlags = Watched(0)
  selectKey = selectKey ?? (item != null
    ? (item?.isShopItem ? item?.basetpl : item?.guid)
    : "_".concat(soldierGuid, slotType ?? "", slotId ?? ""))
  let group = ElemGroup()
  let dropData = { item, slotType, slotId, scheme }
  let isDraggable = item != null && canDrag
  let hasDropExceptionCb = onDropExceptionCb != null

  let canEquipBothItems = @(data)
    canEquip(data?.item, scheme) && ("guid" not in item || canEquip(item, data?.scheme))

  let canDrop = function(data) {
    if (dropData == data)
      return true
    if (data?.slotType == null && dropData.slotType == null)
      return false // drag from storage to storage
    return canEquipBothItems(data)
  }
  let canDropWithExceptionCB = @(data) canDrop(data) || (hasDropExceptionCb && data != null)
  let { isShowDebugOnly = false } = item

  return function() {
    let flags = stateFlags.value
    let isSelected = selectedKey.value == selectKey
    let upgradeData = mkItemUpgradeData(item)
    isAvailable = isAvailable ?? ((item?.guid ?? "") != "")
    let children = isAvailable
      ? [
          itemCtor(item, slotType, itemSize, isSelected, flags, group, true, ammoBox)
          {
            flow = FLOW_HORIZONTAL
            halign = ALIGN_RIGHT
            size = flex()
            children = [
              mkSigns(upgradeData, flags, isSelected, isNew)
              itemCountRarity(item, flags, isSelected)
              hideStatus ? null : statusCtor(item, soldier)
              mkUnseenSign(hasUnseenSign)
            ]
          }
          mods
          hasWarningSign ? statusBadgeWarning : null
        ]
      : item != null ? [
          itemCtor(item, slotType, itemSize, isSelected, flags, group)
          {
            hplace = ALIGN_RIGHT
            vplace = ALIGN_TOP
            children = detailsStatusTier(item)
          }
          {
            flow = FLOW_HORIZONTAL
            children = [
              hideStatus ? null : statusCtor(item, soldier)
              mkUnseenSign(hasUnseenSign)
            ]
          }
          hasWarningSign ? statusBadgeWarning : null
        ]
      : {
          size = flex()
          children = [
            !isLocked ? null : statusIconLocked.__update({ margin = smallPadding })
            !isLocked ? null : {
              rendObj = ROBJ_TEXT
              vplace = ALIGN_BOTTOM
              padding = bigPadding
              color = listTxtColor(flags, isSelected)
              text = loc("slot/locked")
              opacity = 0.5
            }.__update(tiny_txt)
            hasWarningSign ? statusBadgeWarning : null
            {
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_RIGHT
              children = [
                emptySlotChildren(slotType, itemSize, isSelected, flags, group)
                mkUnseenSign(hasUnseenSign)
              ]
            }
          ]
        }
    return {
      watch = [stateFlags, selectedKey, itemDragData, objInfoByGuid]
      stopMouse = true
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_BOX
      fillColor = isShowDebugOnly ? 0xFF003366
        : isDisabled ? fadedTxtColor
        : isLocked ? blockedBgColor
        : bgColor
      borderWidth = !isLocked && canDrop(itemDragData.value) ? 1 : 0
      children = {
        size = itemSize
        eventPassThrough = isDraggable
        transform = {}
        behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
        group = group
        function onDragMode(on, data) {
          if (on)
            sound_play("ui/inventory_item_take")
          itemDragData.update(on ? data : null)
        }
        function onClick(event) {
          if (!isInteractive)
            return
          if (isLocked) {
            onResearchClickCb?(soldier.value, slotType, slotId)
            return
          }
          onClickCb?(itemDesc.__merge({ rectOrPos = event.targetRect }))
        }
        function onDoubleClick(event) {
          if (isLocked || !isInteractive || onDoubleClickCb == null)
            return
          onDoubleClickCb(itemDesc.__merge({ rectOrPos = event.targetRect }))
        }
        function onDrop(data) {
          if (isLocked)
            return
          if (onDropExceptionCb != null && !canEquipBothItems(data) && data?.item != null) {
            onDropExceptionCb(data.item)
            return
          }
          let isItemEquipping = trySwapItems(soldierGuid, dropData, data)
          if (isItemEquipping)
            sound_play("ui/inventory_item_place")
        }
        function onHover(on) {
          curHoveredItem(on ? item : null)
          onHoverCb?(on)
          cursors.setTooltip(on && item && !pauseTooltip.value
            ? makeToolTip(item, canDrag, slotType != null, canDrag && onDoubleClickCb != null)
            : null)
        }
        dropData = isDraggable ? dropData : null
        canDrop = canDropWithExceptionCB
        children = children
        clipChildren = true
        onElemState = isInteractive ? (@(sf) stateFlags(sf)) : null
      }.__update(bgStyle(flags, isSelected),
        isXmb ? { xmbNode = XmbNode() } : {},
        isDraggable ? { cursor = cursors.draggable } : {})
    }
  }
}

return {
  mkItem = kwarg(mkItem)
  amountText
  smallMainColorText
}
