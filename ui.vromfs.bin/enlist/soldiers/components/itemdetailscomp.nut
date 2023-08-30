from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, smallPadding, inventoryItemDetailsWidth, midPadding, totalBlack,
  defItemBlur, transpDarkPanelBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { statusTier, statusHintText, statusIconCtor } = require("%enlSqGlob/ui/itemPkg.nut")
let { getItemName, getItemTypeName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("itemTypesData.nut")
let mkItemLevelData = require("%enlist/soldiers/model/mkItemLevelData.nut")
let { mkItemDescription, mkVehicleDetails, mkItemDetails, mkUpgrades, BASE_COLOR
} = require("itemDetailsPkg.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { mkSpecialItemIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { inventoryItems } = require("%enlist/soldiers/model/selectItemState.nut")
let { makeGradientVertScroll, styling } = require("%ui/components/scrollbar.nut")

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "itemDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "itemDetailsAnim"}
]

let inStockInfo = @(item) function() {
  let count = inventoryItems.value?[item.basetpl].count ?? 0
  return count < 1 ? { watch = inventoryItems } : {
    watch = inventoryItems
    children = {
      rendObj = ROBJ_TEXT
      maxWidth = inventoryItemDetailsWidth
      halign = ALIGN_RIGHT
      text = loc("itemCurrentCount", { count })
      color = BASE_COLOR
    }.__update(fontSub)
  }
}

let lockedInfo = @(demands) {
  size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  children = [
    statusHintText(demands)
    statusIconCtor(demands)
  ]
}

let mkInfoRow = @(text, value) {
  rendObj = ROBJ_TEXT
  maxWidth = inventoryItemDetailsWidth
  halign = ALIGN_RIGHT
  text = $"{text}: {value}"
  color = defTxtColor
}.__update(fontSub)

let mkSlotIncreaseInfo = @(item) function() {
  let res = { watch = configs }
  let incInfo = {}
  foreach (slotType, tplsList in configs.value?.equip_slot_increase ?? {})
    if (item.basetpl in tplsList)
      incInfo[slotType] <- tplsList[item.basetpl]
  if (incInfo.len() == 0)
    return res
  return res.__update({
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = incInfo
      .map(@(count, slotType) mkInfoRow(loc($"itemDetails/slotsIncrease/{slotType}"), count))
      .values()
  })
}

let mkAmmoIncreaseInfo = @(item) function() {
  let res = { watch = configs }
  let value = configs.value?.equip_ammo_increase[item.basetpl] ?? 0
  if (value == 0)
    return res
  let perc = (100.0 * value + 0.5).tointeger()
  return mkInfoRow(loc("itemDetails/ammoIncrease"), $"+{perc}%")
}

let itemTitle = @(item, maxWidth) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_RIGHT
  text = getItemName(item)
  color = titleTxtColor
}.__update(fontBody)

let detailsStatusTier = @(item) @() {
  watch = [needFreemiumStatus, campPresentation]
  children = statusTier(
    item,
    mkItemLevelData(item),
    needFreemiumStatus.value,
    campPresentation.value?.color,
    @(v) v
  )
}

local lastTpl = null

let mkRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  valign = ALIGN_CENTER
  children = children
}

let function mkTypeIcon(itemtype, itemsubtype) {
  if (itemtype == null)
    return null

  let children = itemTypeIcon(itemtype, itemsubtype)
  return children == null ? null
    : {
        size = [hdpx(30), hdpx(30)]
        margin = smallPadding
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
        fillColor = totalBlack
        color = totalBlack
        children
      }
}

let function mkItemHeader(item, isFull) {
  let isVehicle = item?.itemtype == "vehicle"
  let specialIcon = mkSpecialItemIcon(item, hdpxi(27))
  let titleWidth = inventoryItemDetailsWidth * (isFull ? 1 : 0.92) - ((specialIcon != null)
    ? hdpx(57) : hdpx(27))
  local typeLoc = getItemTypeName(item)
  typeLoc = typeLoc == "" ? null
    : {
      rendObj = ROBJ_TEXT
      text = typeLoc
      color = BASE_COLOR
    }.__update(fontSub)
  let itemType = isVehicle ? item?.itemsubtype : item?.itemtype
  return {
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = { size = flex() }
        valign = ALIGN_CENTER
        children = [
          mkRow([
            specialIcon
            mkTypeIcon(itemType, null)
          ])
          {
            flow = FLOW_VERTICAL
            halign = ALIGN_RIGHT
            gap = smallPadding
            children = [
              typeLoc
              detailsStatusTier(item)
            ]
          }
        ]
      }
      itemTitle(item, titleWidth)
      inStockInfo(item)
    ]
  }
}

let function mkDetailsInfo(item, isFull = true, maxHeight = SIZE_TO_CONTENT) {
  let isVehicle = item?.itemtype == "vehicle"
  return makeGradientVertScroll({
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = defItemBlur
    fillColor = transpDarkPanelBgColor
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = midPadding
    size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
    padding = midPadding
    vplace = isFull ? ALIGN_TOP : ALIGN_BOTTOM
    valign = ALIGN_BOTTOM
    children = [
      mkItemHeader(item, isFull)
      isFull ? mkItemDescription(item) : null
      isVehicle ? null : mkSlotIncreaseInfo(item)
      isVehicle ? null : mkAmmoIncreaseInfo(item)
      isVehicle ? mkVehicleDetails(item) : mkItemDetails(item, isFull)
      mkUpgrades(item, isFull)
    ]
  }, {
    size = SIZE_TO_CONTENT
    rootBase = { behavior = Behaviors.Pannable }
    styling = styling.__merge({ Bar = styling.Bar(false) })
    gradientSize = hdpx(100)
    vplace = ALIGN_BOTTOM
    maxHeight
  })
}

let mkViewItemWatchDetails = @(viewItemWatch, isFullMode = Watched(true)) function() {
  let res = {
    watch = [viewItemWatch, isFullMode]
    transform = {}
    animations = animations
  }
  let item = viewItemWatch.value
  let tpl = item?.basetpl
  if (lastTpl != tpl) {
    lastTpl = tpl
    anim_start("itemDetailsAnim")
  }
  if (!tpl)
    return res

  let isFull = isFullMode.value
  return res.__update({
    key = tpl
    children = mkDetailsInfo(item, isFull)
  })
}

let function mkViewItemDetails (item, isFullMode = Watched(true), maxHeight = SIZE_TO_CONTENT) {
  let tpl = item?.basetpl
  if (lastTpl != tpl) {
    lastTpl = tpl
    anim_start("itemDetailsAnim")
  }
  if (!tpl)
    return null

  return @() {
    watch = isFullMode
    key = tpl
    transform = {}
    animations = animations
    children = mkDetailsInfo(item, isFullMode.value, maxHeight)
  }
}
return {
  mkViewItemDetails
  mkViewItemWatchDetails
  lockedInfo
  detailsStatusTier
  mkTypeIcon
}
