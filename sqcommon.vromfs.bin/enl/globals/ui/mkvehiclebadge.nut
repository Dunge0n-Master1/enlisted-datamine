from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { getVehSkins } = require("%enlSqGlob/vehDecorUtils.nut")
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { statusTier } = require("%enlSqGlob/ui/itemPkg.nut")
let {
  colFull, colPart, columnGap, midPadding, defTxtColor, smallPadding,
  defSlotBgImg, hoverSlotBgImg, bigPadding
} = require("%enlSqGlob/ui/designConst.nut")


let slotSize = [colFull(3), colPart(1.02) * 2 + 3 * columnGap]


let vehicleBg = @(flags, isSelected) isSelected ? hoverSlotBgImg
    : flags & S_HOVER ? hoverSlotBgImg
    : defSlotBgImg


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)


let function mkVehicleImage(gametemplate, skinId) {
  let genOverride = {}
  if (skinId != null) {
    let skin = (getVehSkins(gametemplate) ?? []).findvalue(@(s) s.id == skinId)
    if ("objTexReplace" in skin)
      genOverride.objTexReplace <- skin.objTexReplace
  }
  let width = slotSize[0]
  let height = slotSize[1]
  return iconByGameTemplate(gametemplate, { width, height, genOverride })
}


let mkHeaderText = @(text) {
  padding = [0, smallPadding]
  pos = [0, -(columnGap + bigPadding)]
  rendObj = ROBJ_TEXT
  text
}.__update(defTxtStyle)


let mkVehicleInfo = @(vehicleInfo, isNameAbove) {
  size = flex()
  children = [
    isNameAbove ? mkHeaderText(getItemName(vehicleInfo)) : null
    {
      size = flex()
      padding = midPadding
      children = [
        statusTier(vehicleInfo)
        isNameAbove ? null
          : {
              vplace = ALIGN_BOTTOM
              rendObj = ROBJ_TEXT
              text = getItemName(vehicleInfo)
            }.__update(defTxtStyle)
      ]
    }
  ]
}

let function mkVehicleBadge(
  vehicleInfo, isSelected, sf = 0, onClick = null, isNameAbove = true
) {
  let { gametemplate = "", skin = null } = vehicleInfo
  return {
    key = $"vehicle_badge_{gametemplate}"
    size = slotSize
    rendObj = ROBJ_MASK
    image = Picture("ui/uiskin/vehicle_slot_mask.avif")
    behavior = onClick == null ? null : Behaviors.Button
    onClick
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = vehicleBg(sf, isSelected)
        children = gametemplate == "" ? null
          : [
              mkVehicleImage(gametemplate, skin?.id)
              mkVehicleInfo(vehicleInfo, isNameAbove)
            ]
      }
    ]
  }
}

return {
  mkVehicleBadge
}
