from "%enlSqGlob/ui_library.nut" import *

let mkItemBadge = require("components/mkItemBadge.nut")

let { iconByItem } = require("%enlSqGlob/ui/itemsInfo.nut")
let { colPart, columnGap } = require("%enlSqGlob/ui/designConst.nut")
let { getModSlots, objInfoByGuid, curArmy } = require("model/state.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { modSize } = require("model/config/equipSlots.nut")


let miniSlotSize = [colPart(1), colPart(1)]

let MAKE_PARAMS = {
  item = null
  itemSize = miniSlotSize
  soldierGuid = null
  isInteractive = true
  isDisabled = false
  isNew = false
  canDrag = false
  onClickCb = @(_) null
  onDoubleClickCb = null
  onDropExceptionCb = null
  onHoverCb = null
  selectedKey = Watched(null)
  isXmb = false
  hasTypeIcon = false
  hasUnseenSign = Watched(false)
  hasModsUnseenSign = Watched(false)
}


let modItemCtor = @(item, itemSize, _hasTypeIcon)
  iconByItem(item, {
    width = itemSize[0] - columnGap
    height = itemSize[1] - columnGap
  })


let function getModData(mainItem, slot) {
  if ((mainItem?.guid ?? "") != "")
    return objInfoByGuid.value?[slot.equipped]

  let [ basetpl = null ] = slot?.scheme.items
  return allItemTemplates.value?[curArmy.value][basetpl]
}


let function mkItemMods(p) {
  let slots = getModSlots(p.item)
  if (slots.len() == 0)
    return null

  return {
    size = SIZE_TO_CONTENT
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_HORIZONTAL
    stopHover = true
    children = slots.map(@(slot) mkItemBadge({
      isXmb = p.isXmb
      item = getModData(p.item, slot)
      itemSize = modSize
      scheme = slot.scheme
      soldierGuid = p.item.guid
      slotType = slot.slotType
      isInteractive = p.isInteractive
      hasUnseenSign = p.hasUnseenSign
      isDisabled = p.isDisabled
      canDrag = p.canDrag
      onClickCb = p.onClickCb
      onDoubleClickCb = p.onDoubleClickCb
      onHoverCb = p.onHoverCb
      selectedKey = p.selectedKey
      itemCtor = modItemCtor
      emptySlotChildren = @(...) null
    }, KWARG_NON_STRICT))
  }
}


let function mkItemWithMods(p = MAKE_PARAMS) {
  p = MAKE_PARAMS.__merge(p)

  let mods = mkItemMods(p.__merge({ hasUnseenSign = p.hasModsUnseenSign }))
  if (mods)
    p.__update({ mods })

  return {
    size = SIZE_TO_CONTENT
    children = mkItemBadge(p, KWARG_NON_STRICT)
  }
}

return mkItemWithMods
