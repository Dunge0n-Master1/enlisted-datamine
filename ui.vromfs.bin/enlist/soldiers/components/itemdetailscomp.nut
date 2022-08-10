from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, detailsHeaderColor, smallPadding, inventoryItemDetailsWidth, unitSize
} = require("%enlSqGlob/ui/viewConst.nut")
let { statusTier, statusHintText, statusIconCtor } = require("%enlSqGlob/ui/itemPkg.nut")
let { mkItemDemands } = require("%enlist/soldiers/model/mkItemDemands.nut")
let { getItemName, getItemTypeName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("itemTypesData.nut")
let mkItemLevelData = require("%enlist/soldiers/model/mkItemLevelData.nut")
let { blur, mkItemDescription, mkVehicleDetails, mkItemDetails, mkUpgrades
} = require("itemDetailsPkg.nut")
let { configs } = require("%enlSqGlob/configs/configs.nut")
let mkSpecialItemIcon = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")
let { inventoryItems } = require("%enlist/soldiers/model/selectItemState.nut")

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "itemDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "itemDetailsAnim"}
]

let lockedInfo = function(item) {
  let demandsWatch = mkItemDemands(item)
  let watch = [demandsWatch, inventoryItems]
  return function() {
    let demands = demandsWatch.value
    if (demands == null) {
      let count = inventoryItems.value?[item.basetpl].count ?? 0
      return count < 1 ? { watch } : blur({
        watch
        children = {
          size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXT
          maxWidth = inventoryItemDetailsWidth
          halign = ALIGN_RIGHT
          text = loc("itemCurrentCount", { count })
          color = defTxtColor
        }.__update(sub_txt)
      })
    }
    return blur({
      watch
      size = [inventoryItemDetailsWidth + smallPadding * 2, SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        statusHintText(demands)
        statusIconCtor(demands)
      ]
    })
  }
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

let function detailsStatusTier(item, isBlur = false) {
  return @() {
    watch = needFreemiumStatus
    children = statusTier(
      item,
      mkItemLevelData(item),
      needFreemiumStatus.value,
      isBlur ? blur : @(v) v
    )
  }
}

local lastTpl = null

let mkDetailsInfo = @(viewItemWatch, isLocked = true) function() {
  let res = {
    watch = viewItemWatch
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

  let typeLoc = getItemTypeName(item)
  let isVehicle = item?.itemtype == "vehicle"
  let itemType = isVehicle ? item?.itemsubtype : item?.itemtype
  let size = [unitSize * 10, SIZE_TO_CONTENT]
  return res.__update({
    size
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = smallPadding
    children = [
      blur({
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        children = [
          {
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            children = [
              itemTypeIcon(itemType, null, { size = [hdpx(27), hdpx(27)] })
              mkSpecialItemIcon(item, hdpx(30))
              itemTitle(item)
            ]
          }
          typeLoc == "" ? null : {
            rendObj = ROBJ_TEXT
            text = typeLoc
            color = defTxtColor
          }.__update(sub_txt)
        ]
      })
      detailsStatusTier(item, true)
      isLocked ? lockedInfo(item) : null
      isVehicle ? mkItemDescription(item, size) : mkItemDescription(item)
      mkSlotIncreaseInfo(item)
      mkAmmoIncreaseInfo(item)
      isVehicle ? mkVehicleDetails(item, size) : mkItemDetails(item)
      isVehicle ? mkUpgrades(item, size) : mkUpgrades(item)
    ]
  })
}

return {
  mkDetailsInfo
  detailsStatusTier
}
