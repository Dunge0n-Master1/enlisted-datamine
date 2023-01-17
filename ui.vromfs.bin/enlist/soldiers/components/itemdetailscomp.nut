from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, detailsHeaderColor, smallPadding, inventoryItemDetailsWidth
} = require("%enlSqGlob/ui/viewConst.nut")
let { statusTier, statusHintText, statusIconCtor } = require("%enlSqGlob/ui/itemPkg.nut")
let { getItemName, getItemTypeName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("itemTypesData.nut")
let mkItemLevelData = require("%enlist/soldiers/model/mkItemLevelData.nut")
let { blur, mkItemDescription, mkVehicleDetails, mkItemDetails, mkUpgrades, BASE_COLOR
} = require("itemDetailsPkg.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { mkSpecialItemIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { campPresentation, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { inventoryItems } = require("%enlist/soldiers/model/selectItemState.nut")

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
    }.__update(sub_txt)
  }
}

let lockedInfo = @(demands) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
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
}.__update(sub_txt)

let mkSlotIncreaseInfo = @(item) function() {
  let res = { watch = configs }
  let incInfo = {}
  foreach (slotType, tplsList in configs.value?.equip_slot_increase ?? {})
    if (item.basetpl in tplsList)
      incInfo[slotType] <- tplsList[item.basetpl]
  if (incInfo.len() == 0)
    return res
  return blur(res.__update({
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = incInfo
      .map(@(count, slotType) mkInfoRow(loc($"itemDetails/slotsIncrease/{slotType}"), count))
      .values()
  }))
}

let mkAmmoIncreaseInfo = @(item) function() {
  let res = { watch = configs }
  let value = configs.value?.equip_ammo_increase[item.basetpl] ?? 0
  if (value == 0)
    return res
  let perc = (100.0 * value + 0.5).tointeger()
  return blur(mkInfoRow(loc("itemDetails/ammoIncrease"), $"+{perc}%"))
}

let itemTitle = @(item) {
  maxWidth = inventoryItemDetailsWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  text = getItemName(item)
  color = detailsHeaderColor
}.__update(body_txt)

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
  children = children
}

let function mkItemHeader(item) {
  let isVehicle = item?.itemtype == "vehicle"
  local  typeLoc = getItemTypeName(item)
  typeLoc = typeLoc == "" ? null
    : {
      rendObj = ROBJ_TEXT
      text = typeLoc
      color = BASE_COLOR
    }.__update(sub_txt)
  let itemType = isVehicle ? item?.itemsubtype : item?.itemtype
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    size = [flex(), SIZE_TO_CONTENT]
    gap = smallPadding
    children = [
      mkRow([
        itemTypeIcon(itemType, null, { size = [hdpx(27), hdpx(27)] })
        mkSpecialItemIcon(item, hdpx(30))
        itemTitle(item)
      ])
      mkRow([
        detailsStatusTier(item)
        typeLoc
      ])
      inStockInfo(item)
    ]
  }
}

let mkDetailsInfo = @(viewItemWatch, isFullMode = Watched(true))
  function() {
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

    let isVehicle = item?.itemtype == "vehicle"
    let isFull = isFullMode.value

    return res.__update(blur({
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      gap = smallPadding
      children = [
        mkItemHeader(item)
        isFull ? mkItemDescription(item) : null
        isVehicle ? null : mkSlotIncreaseInfo(item)
        isVehicle ? null : mkAmmoIncreaseInfo(item)
        isVehicle ? mkVehicleDetails(item, isFull) : mkItemDetails(item, isFull)
        mkUpgrades(item, isFull)
      ]
    }))
  }

return {
  mkDetailsInfo
  lockedInfo
  detailsStatusTier
}
