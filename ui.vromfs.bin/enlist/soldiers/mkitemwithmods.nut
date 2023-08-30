from "%enlSqGlob/ui_library.nut" import *

let { smallPadding, unitSize, bigPadding, soldierWndWidth, hoverBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { fullTransparentBgColor, modsBgColor } = require("%enlSqGlob/ui/designConst.nut")

let { getModSlots, objInfoByGuid, curArmy } = require("model/state.nut")
let { mkItem } = require("components/itemComp.nut")
let { iconByItem } = require("%enlSqGlob/ui/itemsInfo.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")

let defItemSize = [soldierWndWidth - 2 * bigPadding, 2 * unitSize] //!!TODO: move it to style
let MAKE_PARAMS = { //+all params of itemComp
  item = null
  itemSize = defItemSize
  soldierGuid=null
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
  hasUnseenSign = Watched(false)
}

let modItemCtor = @(item, itemSize) iconByItem(item, {
  width = itemSize[0] - 2 * smallPadding
  height = itemSize[1] - 2 * smallPadding
})

let modsColor = mul_color(modsBgColor, 0.6)

let modBgStyle = @(sf, _isSelected, _bgColor) {
  rendObj = ROBJ_WORLD_BLUR
  color = fullTransparentBgColor
  fillColor = sf & S_HOVER ? hoverBgColor
    : modsColor
}

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

  let modHeight = 0.45 * p.itemSize[1]
  let modSize = [1.8 * modHeight, modHeight]
  return {
    size = modSize
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_HORIZONTAL
    stopHover = true
    children = slots.map(@(slot) mkItem({
      isXmb = p.isXmb
      item = getModData(p.item, slot)
      itemSize = modSize
      scheme = slot.scheme
      soldierGuid = p.item.guid
      slotType = slot.slotType
      bgStyle = modBgStyle
      isInteractive = p.isInteractive
      isDisabled = p.isDisabled
      canDrag = p.canDrag
      onClickCb = p.onClickCb
      onDoubleClickCb = p.onDoubleClickCb
      onHoverCb = p.onHoverCb
      selectedKey = p.selectedKey

      itemCtor = modItemCtor
      needItemName = false
      emptySlotName = @(...) null
    }))
  }
}

local function mkItemWithMods(p = MAKE_PARAMS) {
  p = MAKE_PARAMS.__merge(p)
  let mods = mkItemMods(p)
  if (mods)
    p.__update({ mods })

  return {
    size = p.itemSize
    children = mkItem(p, KWARG_NON_STRICT)
  }
}

return mkItemWithMods