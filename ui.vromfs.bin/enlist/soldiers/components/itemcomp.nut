from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let faComp = require("%ui/components/faComp.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { unitSize, gap, bigGap, bigPadding, smallPadding, fadedTxtColor,
  selectedTxtColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { defLockedSlotBgColor, hoverLockedSlotBgColor, darkTxtColor,
  defSlotBgColor, hoverSlotBgColor, defItemBlur, modsBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkLockedBlock, mkEmptyItemSlotImg } = require("%enlist/soldiers/components/itemSlotComp.nut")
let { statusIconCtor, statusBadgeWarning } = require("%enlSqGlob/ui/itemPkg.nut")
let { mkItemDemands } = require("%enlist/soldiers/model/mkItemDemands.nut")
let { objInfoByGuid, getItemOwnerGuid, getSoldierItemSlots, getItemIndex,
  getDemandingSlots, getDemandingSlotsInfo, getEquippedItemGuid
} = require("%enlist/soldiers/model/state.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")
let { equipItem, swapItems } = require("%enlist/soldiers/model/itemActions.nut")
let { iconByItem, getItemName, getItemDesc, trimUpgradeSuffix
} = require("%enlSqGlob/ui/itemsInfo.nut")
let { curHoveredItem } = require("%enlist/showState.nut")
let popupsState = require("%enlSqGlob/ui/popup/popupsState.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let cursors = require("%ui/style/cursors.nut")
let { unequipItem } = require("%enlist/soldiers/unequipItem.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { mkAmmoInfo } = require("mkAmmo.nut")
let { getWeaponData } = require("%enlist/soldiers/model/collectWeaponData.nut")
let { mkSpecialItemIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { detailsStatusTier, mkTypeIcon } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { isObjGuidBelongToRentedSquad } = require("%enlist/soldiers/model/squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")
let { mkAlertIcon, ITEM_ALERT_SIGN } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { previewHighlightColor } = require("%enlist/preset/presetEquipUi.nut")
let { itemTypesInSlots } = require("%enlist/soldiers/model/all_items_templates.nut")

let DISABLED_ITEM = { tint = Color(40, 40, 40, 160), picSaturate = 0.0 }
let baseItemSize = [7 * unitSize, 2 * unitSize] // 320px is max

let listTxtColor = @(flags, selected = false)
  (flags & S_HOVER) || (flags & S_ACTIVE) || selected ? selectedTxtColor : defTxtColor

let itemDragData = Watched()

let amountText = @(count, sf, selected) {
  rendObj = ROBJ_SOLID
  color = selected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_TEXT
    color = listTxtColor(sf, selected)
    text = loc("common/amountShort", { count })
  }.__update(fontSub)
}

let defSlotnameCtor = function(slotType, group, selected) {
  if (slotType == null)
    return null
  let text = loc($"inventory/{slotType}", "")
  return watchElemState(@(sf) {
      rendObj = ROBJ_TEXT
      group
      watch = selected
      margin = smallPadding
      hplace = ALIGN_LEFT
      color = listTxtColor(sf, selected.value)
      text
      opacity = 0.5
    }.__update(fontSub))
}

let mkSlotName = @(text, isSelected, group) watchElemState(@(sf) {
  watch = isSelected
  group
  size = [flex(), SIZE_TO_CONTENT]
  clipChildren = true
  children = {
    behavior = Behaviors.Marquee
    group
    scrollOnHover = true
    size = [flex(), SIZE_TO_CONTENT]
    children = {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_BOTTOM
      color = listTxtColor(sf, isSelected.value)
      text
    }.__update(fontSub)
  }
})

let mkNameBlock = @(item, slotName) {
  size =  [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  vplace = ALIGN_BOTTOM
  children = [
    detailsStatusTier(item)
    slotName
  ]
}

let MAX_ICON_SIZE = unitSize * 7

let isMainWeapon = @(item) (item?.itemtype ?? "") in itemTypesInSlots.value?.mainWeapon

let bigWeapons = {
  mgun = true
  submgun = true
  assault_rifle = true
  assault_rifle_stl = true
  carbine_pistol = true
  semiauto_sniper = true
  semiauto = true
  rifle_grenade_launcher = true
  rifle_at_grenade_launcher = true
  mortar = true
  launcher = true
  antitank_rifle = true
}

let defIcon = @(item, size, override = {}) iconByItem(item, {
  vplace = ALIGN_TOP
  hplace = ALIGN_CENTER
  width  = min(MAX_ICON_SIZE, size[0]) - 2 * smallPadding
  height = size[1] - 2 * smallPadding
  margin = smallPadding
}.__update(override))

let smgIcon = @(item, size) defIcon(item, size, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  pos    = [bigPadding * 3, 0]
})

let gunIcon = @(item, size) defIcon(item, size, {
  hplace = ALIGN_LEFT
  pos    = [bigPadding * 3, 0]
})

let pistolIcon = @(item, size) defIcon(item, size, {
  vplace = ALIGN_CENTER
})

let bigIconSize = [(unitSize * 6.3).tointeger(), (unitSize * 3.6).tointeger()]

let forBigWeapon = @(item, _size) (item?.itemtype ?? "") in bigWeapons
  ? smgIcon(item, bigIconSize) : null

let forMainWeapon = @(item, size) isMainWeapon(item)
  ? gunIcon(item, size.map(@(v) v*0.7)) : null

let forAmmoWeapon = function(item, size) {
  let { caliber = null, bullets = null } = getWeaponData(item?.gametemplate ?? "")
  if (caliber == null && bullets == null)
    return null
  return pistolIcon(item, size.map(@(v) v*0.7))
}

let iconVariants = [
  forBigWeapon
  forMainWeapon
  forAmmoWeapon
  defIcon
]

let defItemCtor = function(item, size) {
  local icon
  foreach (cb in iconVariants) {
    icon = cb(item, size)
    if (icon)
      break
  }
  return icon
}

let mkItemCount = @(count) count > 1 ? {
  rendObj = ROBJ_BOX
  fillColor = modsBgColor
  padding = [0, bigPadding]
  children = {
    rendObj = ROBJ_TEXT
    defTxtColor
    text = loc("common/amountShort", { count })
  }.__update(fontSub)
} : null

let itemSlotCtor = function(item, itemSize, itemCtor, group, isSelected, isAvailable,
  slotName, slotType, soldierGuid, mods, status, unseenSign) {

  let weapData = getWeaponData(item?.gametemplate ?? "")
  let needShowAmmo = weapData?.caliber != null || weapData?.bullets != null
  let itemIcon = itemCtor(item, itemSize)
  if (itemIcon != null && !isAvailable) {
    itemIcon.__update(DISABLED_ITEM)
  }

  return watchElemState(function(sf) {
    let color = (sf & S_HOVER) || isSelected.value ? darkTxtColor : defTxtColor
    let ammoBox = needShowAmmo
      ? mkAmmoInfo(item, soldierGuid, weapData, slotType, {
          color
          hplace = ALIGN_RIGHT
          vplace = ALIGN_CENTER
          padding = [smallPadding, bigPadding]
        })
      : null

    return {
      size = flex()
      group
      watch = isSelected
      children = [
        mkSpecialItemIcon(item, hdpxi(32), { margin = 0 })
        itemIcon
        {
          flow = FLOW_VERTICAL
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          halign = ALIGN_RIGHT
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = [
                unseenSign
                ammoBox
              ]
            }
            {
              vplace = ALIGN_RIGHT
              padding = [0, bigPadding]
              children = mods
            }
          ]
        }
        {
          size =  [flex(), SIZE_TO_CONTENT]
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          flow = FLOW_HORIZONTAL
          padding = [smallPadding, bigPadding]
          gap = smallPadding
          children = [
            isMainWeapon(item) ? mkTypeIcon(item?.itemtype, item?.itemsubtype) : null
            mkNameBlock(item, slotName)
            mkItemCount(item?.count ?? 1)
          ]
        }
        {
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_RIGHT
          margin = smallPadding
          children = status
        }
      ]
    }
  })
}

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
  if (item?.basetpl == toItem?.basetpl)
    // do not swap same items
    return true

  if (checkFixedItem(toItem))
    return false

  // dropping item from the soldier's card into storage:
  if (targetDropData.scheme == null){
    // dropping item into empty storage slot, unequip:
    if ("guid" not in targetDropData.item) {
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
    }.__update(fontSub)
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
          }.__update(fontBody)
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

let defBgStyle = @(sf, isSelected, bgColor) {
  rendObj = ROBJ_WORLD_BLUR
  fillColor = isSelected || (sf & S_HOVER) ? hoverSlotBgColor : bgColor
  color = isSelected ? hoverSlotBgColor : defItemBlur
}

let function defIconCtor(item, soldierWatch) {
  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.value)
  }
}

let mkUnseenSign = @(hasUnseenSign) mkAlertIcon(ITEM_ALERT_SIGN, hasUnseenSign)

let defEmptyItemCtor = @(slotName, emptyItemImg, unseenSign) {
  size = flex()
  children = [
    slotName
    emptyItemImg
    unseenSign
  ]
}

let lockedSlotCtor = @(children, group, isLocked, hasWarningSign) watchElemState(@(sf) {
  size = flex()
  group
  children = [
    mkLockedBlock(sf & S_HOVER ? hoverLockedSlotBgColor : defLockedSlotBgColor)
    {
      size = flex()
      children = [
        !isLocked ? null : {
          rendObj = ROBJ_TEXT
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_RIGHT
          padding = smallPadding
          color = listTxtColor(sf)
          text = loc("slot/locked")
          opacity = 0.5
        }.__update(fontSub)
        hasWarningSign ? statusBadgeWarning : null
        {
          flow = FLOW_HORIZONTAL
          hplace = ALIGN_LEFT
          children
        }
      ]
    }
  ]
})

local function mkItem(slotId = null, item = null, slotType = null, itemSize = baseItemSize,
  emptySlotName = defSlotnameCtor, scheme = null, itemCtor = defItemCtor,
  onDropExceptionCb = null, statusCtor = defIconCtor, soldierGuid = null, isInteractive = true,
  isDisabled = false, canDrag = true, bgStyle = defBgStyle, selectedKey = Watched(null),
  selectKey = null, isXmb = false, bgColor = defSlotBgColor, pauseTooltip = Watched(false),
  onClickCb = null, onHoverCb = null, isLocked = false, onDoubleClickCb = null,
  onResearchClickCb = null, mods = null, hasUnseenSign = Watched(false), isAvailable = null,
  hideStatus = false, hasWarningSign = false, needItemName = true,
  slotImg = null, previewState = null
) {
  if (isDisabled)
    isInteractive = false

  let soldier = Computed(@() objInfoByGuid.value?[soldierGuid])
  if (type(item) == "string")
    item = objInfoByGuid.value?[item]
  let itemDesc = { item, slotType, soldierGuid, slotId, scheme }

  let stateFlags = Watched(0)
  selectKey = selectKey ?? (item != null
    ? (item?.isShopItem ? item?.basetpl : item?.guid)
    : "_".concat(soldierGuid, slotType ?? "", slotId ?? ""))
  let group = isInteractive ? ElemGroup() : null
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
  let iconSize = (itemSize[1] * 0.5).tointeger()

  let isSelected = Computed(@() selectedKey.value == selectKey)
  isAvailable = isAvailable ?? ((item?.guid ?? "") != "")

  let slotName = needItemName && item != null
    ? mkSlotName(getItemName(item), isSelected, group)
    : emptySlotName(slotType, group, isSelected)

  let status = hideStatus ? null : statusCtor(item, soldier)
  let unseenSign = mkUnseenSign(hasUnseenSign)

  let itemObj = (isAvailable || item != null)
  ? itemSlotCtor(item, itemSize, itemCtor, group, isSelected, isAvailable, slotName, slotType,
      soldierGuid, mods, status, unseenSign)
  : isDisabled || isLocked
    ? lockedSlotCtor(slotName, group, isLocked, hasWarningSign)
    : defEmptyItemCtor(slotName, mkEmptyItemSlotImg(slotImg, iconSize, group, isSelected), unseenSign)

  let override = {}
  if (isXmb)
    override.xmbNode <- XmbNode()
  if (isDraggable)
    override.cursor <- cursors.draggable

  return @() {
      watch = [stateFlags, isSelected, itemDragData, objInfoByGuid]
      stopMouse = true
      size = flex()
      children = {
        size = flex()
        eventPassThrough = isDraggable
        transform = {}
        behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
        group
        children = {
          rendObj = ROBJ_FRAME
          size = flex()
          borderWidth = previewState == null ? null : hdpx(2)
          color = previewHighlightColor(previewState)
          children = itemObj
        }
        clipChildren = true
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
        onElemState = isInteractive ? (@(sf) stateFlags(sf)) : null
      }.__update(bgStyle(stateFlags.value, isSelected.value, bgColor), override)
    }
}

return {
  mkItem = kwarg(mkItem)
  amountText
}
