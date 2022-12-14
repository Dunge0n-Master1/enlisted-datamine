from "%enlSqGlob/ui_library.nut" import *

let mkAmmo = require("mkAmmo.nut")

let { objInfoByGuid } = require("%enlist/soldiers/model/state.nut")
let { iconByItem } = require("%enlSqGlob/ui/itemsInfo.nut")
let { getWeaponData } = require("%enlist/soldiers/model/collectWeaponData.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { curHoveredItem } = require("%enlist/showState.nut")
let { mkLockedBlock, mkEmptyItemSlotImg } = require("%enlist/soldiers/components/itemSlotComp.nut")
let {
  commonBorderRadius, columnGap, colPart, midPadding, smallPadding,
  lockedItemIdleBgColor, lockedItemHoverBgColor, debugItemBgColor,
  defSlotBgImg, hoverSlotBgImg
} = require("%enlSqGlob/ui/designConst.nut")
let {
  baseItemSize, miniOffset, modSize
} = require("%enlist/soldiers/model/config/equipSlots.nut")


let defItemSize = baseItemSize
let itemTypeIconCircle = colPart(0.55)

let slotsWithMods = {
  primary = true
  secondary = true
  side = true
}

let extraBlock = {
  size = modSize
  margin = 0
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  borderWidth = 0
  fillColor = lockedItemIdleBgColor
}


let bgImage = @(sf, isSelected) isSelected ? hoverSlotBgImg
  : sf & S_HOVER ? hoverSlotBgImg
  : defSlotBgImg


let mkTypeIcon = @(itemtype, itemsubtype) {
  size = [itemTypeIconCircle, itemTypeIconCircle]
  margin = midPadding
  halign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
  fillColor = 0xFF000000
  color = 0xFF000000
  children = itemTypeIcon(itemtype, itemsubtype)
}


let defItemCtor = function(item, itemSize, hasTypeIcon) {
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
      {
        margin = smallPadding
        vplace = ALIGN_BOTTOM
        children = detailsStatusTier(item)
      }
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
  onClickCb = null, onHoverCb = null, onResearchClickCb = null, slotImg = null
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
  let ammoObj = needShowAmmo
    ? mkAmmo(item, soldierGuid, weapData, slotType,
        extraBlock.__merge({
          rendObj = ROBJ_IMAGE
          image = bgImage(0, false)
        }))
    : hasMods ? extraBlock
    : null

  isAvailable = isAvailable ?? ((item?.guid ?? "") != "")
  selectKey = selectKey ?? mkItemKey(item, soldierGuid, slotType, slotId)

  let iconSize = (itemSize[1] * 0.5).tointeger()
  let isSelected = Computed(@() selectedKey.value == selectKey)
  let stateFlags = Watched(0)
  return function() {
    let flags = stateFlags.value
    let lockColor = flags & S_HOVER ? lockedItemHoverBgColor : lockedItemIdleBgColor
    let itemObj = isAvailable ? itemCtor(item, itemSize, hasTypeIcon)
      : isDisabled || isLocked ? mkLockedBlock(lockColor)
      : mkEmptyItemSlotImg(slotImg, iconSize)

    let bgOverride = isDisabled || isLocked || isShowDebugOnly
      ? {
          rendObj = ROBJ_SOLID
          color = isShowDebugOnly ? debugItemBgColor : lockColor
        }
      : {
          rendObj = ROBJ_IMAGE
          image = bgImage(flags, isSelected.value)
        }

    return {
      watch = [stateFlags, isSelected]
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = miniOffset
      stopMouse = true
      behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
      onElemState = @(sf) stateFlags(sf)

      function onHover(on) {
        curHoveredItem(on ? item : null)
        onHoverCb?(on)
      }

      function onClick(event) {
        if (!isInteractive)
          return
        if (isLocked) {
          onResearchClickCb?(objInfoByGuid.value?[soldierGuid], slotType, slotId)
          return
        }
        onClickCb?(itemDesc.__merge({ rectOrPos = event.targetRect }))
      }

      children = [
        {
          size = itemSize
          eventPassThrough = isDraggable
          transform = {}
          behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
          children = itemObj
        }.__update(bgOverride)
        modsObj == null && ammoObj == null ? null
          : {
              flow = FLOW_VERTICAL
              gap = miniOffset
              children = [
                modsObj
                ammoObj
              ]
            }
      ]
    }
  }
}

return kwarg(mkItemBadge)
