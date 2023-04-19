from "%enlSqGlob/ui_library.nut" import *

let { mkAmmoInfo } = require("mkAmmo.nut")
let { defTxtColor, darkTxtColor, defLockedSlotBgColor, hoverLockedSlotBgColor, columnGap, colPart,
  midPadding, smallPadding, commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")
let { objInfoByGuid } = require("%enlist/soldiers/model/state.nut")
let { iconByItem } = require("%enlSqGlob/ui/itemsInfo.nut")
let { getWeaponData } = require("%enlist/soldiers/model/collectWeaponData.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { curHoveredItem } = require("%enlist/showState.nut")
let { mkLockedBlock, mkEmptyItemSlotImg } = require("%enlist/soldiers/components/itemSlotComp.nut")
let { SlotStatuses, mkSlotBgOverride, mkLevelNest
} = require("%enlSqGlob/ui/slotPkg.nut")
let {
  baseItemSize, miniOffset, modSize
} = require("%enlist/soldiers/model/config/equipSlots.nut")
let { previewHighlightColor } = require("%enlist/preset/presetEquipUi.nut")
let { mkSpecialItemIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")


let defItemSize = baseItemSize
let itemTypeIconCircle = colPart(0.55)

let slotsWithMods = {
  primary = true
  secondary = true
  mortar = true
  antitank = true
  flamethrower = true
}

let lockIconColor = 0xFFFFFFFF
let lockIconSize = colPart(0.3)

let extraBlock = {
  size = modSize
  margin = 0
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  borderWidth = 0
  fillColor = defLockedSlotBgColor

  children = {
    rendObj = ROBJ_IMAGE
    size = array(2, lockIconSize)
    image = Picture($"ui/skin#locked_icon.svg:{lockIconSize}:{lockIconSize}:K")
    color = lockIconColor
    opacity = 0.05
  }
}


let function mkTypeIcon(itemtype, itemsubtype) {
  if (itemtype == null)
    return null

  let children = itemTypeIcon(itemtype, itemsubtype)
  return children == null ? null
    : {
        size = [itemTypeIconCircle, itemTypeIconCircle]
        margin = midPadding
        halign = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        valign = ALIGN_CENTER
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
        fillColor = 0xFF000000
        color = 0xFF000000
        children
      }
}


let defItemCtor = function(item, itemSize, hasTypeIcon, btmObject) {
  let itemIcon = iconByItem(item, {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    width = itemSize[0] - columnGap
    height = itemSize[1] - columnGap
  })
  let { itemtype = null, itemsubtype = null } = item
  let typeIcon = hasTypeIcon ? mkTypeIcon(itemtype, itemsubtype) : null

  return {
    size = flex()
    children = [
      itemIcon
      typeIcon
      mkSpecialItemIcon(item, colPart(0.5), true)
      btmObject
    ]
  }
}


let mkItemKey = @(item, soldierGuid, slotType = "", slotId = "") item == null
  ? "_".concat(soldierGuid, slotType, slotId)
  : (item?.isShopItem ? item?.basetpl : item?.guid)


local function mkItemBadge(
  slotId = null, item = null, slotType = null, soldierGuid = null, scheme = null,
  itemCtor = defItemCtor, selectedKey = Watched(null), itemSize = defItemSize,
  isInteractive = true, isDisabled = false, isLocked = false, isAvailable = null,
  selectKey = null, canDrag = true, hasTypeIcon = false, mods = null,
  onClickCb = null, onHoverCb = null, onResearchClickCb = null, slotImg = null,
  previewState = null, isTierHidden = false, onDoubleClickCb = null
) {
  if (isDisabled)
    isInteractive = false

  if (type(item) == "string")
    item = objInfoByGuid.value?[item]

  let { isShowDebugOnly = false } = item
  let isDraggable = item != null && canDrag
  let hasMods = slotsWithMods?[slotType] ?? false

  let itemDesc = { item, slotType, soldierGuid, slotId, scheme }
  let weapData = getWeaponData(item?.gametemplate ?? "")
  let needShowAmmo = weapData?["caliber"] != null || weapData?["bullets"] != null
  let modsObj = mods ?? ( hasMods ? extraBlock : null )

  isAvailable = isAvailable ?? (item != null)
  selectKey = selectKey ?? mkItemKey(item, soldierGuid, slotType, slotId)

  let iconSize = (itemSize[1] * 0.5).tointeger()
  let isSelected = Computed(@() selectedKey.value == selectKey)
  let stateFlags = Watched(0)
  return function() {
    let flags = stateFlags.value
    let isActive = isSelected.value || (flags & S_HOVER)
    let status = isShowDebugOnly ? SlotStatuses.DEBUG
      : isDisabled || isLocked ? SlotStatuses.LOCKED
      : SlotStatuses.GENERAL

    let ammoObj = needShowAmmo
      ? mkAmmoInfo(item, soldierGuid, weapData, slotType, {
          color  = isActive ? darkTxtColor : defTxtColor
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
        })
      : null
    let bottomObject = {
      size = [flex(), SIZE_TO_CONTENT]
      padding = [0, smallPadding]
      children = [
        !isTierHidden || isActive ? detailsStatusTier(item) : null
        ammoObj
      ]
    }
    let btmObject = mkLevelNest(isActive, bottomObject)

    let lockColor = flags & S_HOVER ? hoverLockedSlotBgColor : defLockedSlotBgColor
    let itemObj = isAvailable ? itemCtor(item, itemSize, hasTypeIcon, btmObject)
      : isDisabled || isLocked ? mkLockedBlock(lockColor)
      : mkEmptyItemSlotImg(slotImg, iconSize, (flags & S_HOVER) != 0)

    let onHover = function(on) {
      curHoveredItem(on ? item : null)
      onHoverCb?(on)
    }

    let onClick = function(event) {
      if (!isInteractive)
        return
      if (isLocked) {
        onResearchClickCb?(objInfoByGuid.value?[soldierGuid], slotType, slotId)
        return
      }
      onClickCb?(itemDesc.__merge({ rectOrPos = event.targetRect }))
    }

    return {
      watch = [stateFlags, isSelected]
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = miniOffset
      children = [
        {
          size = itemSize
          eventPassThrough = isDraggable
          transform = {}
          behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
          stopHover = true
          onElemState = @(sf) stateFlags(sf)
          onHover
          onClick
          onDoubleClick = onDoubleClickCb
          children = {
            rendObj = ROBJ_FRAME
            size = flex()
            borderWidth = previewState == null ? null : hdpx(2)
            color = previewHighlightColor(previewState)
            children = itemObj
          }
        }.__update(mkSlotBgOverride(isActive, status))
        modsObj
      ]
    }
  }
}

return kwarg(mkItemBadge)
