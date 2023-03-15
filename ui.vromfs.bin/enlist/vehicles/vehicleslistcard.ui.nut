from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  defBgColor, hoverTxtColor, defTxtColor, activeBgColor, hoverBgColor, blockedBgColor,
  vehicleListCardSize, smallPadding, listCtors
} = require("%enlSqGlob/ui/viewConst.nut")
let { txtColor } = listCtors
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { autoscrollText } = require("%enlSqGlob/ui/defcomps.nut")
let { blinkUnseenIcon, noBlinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let {
  viewVehicle, selectedVehicle, curSquad, curSquadArmy, LOCKED, CANT_USE
} = require("vehiclesListState.nut")
let { statusIconChosen, statusIconLocked } = require("%enlSqGlob/ui/itemPkg.nut")
let {
  unseenSquadsVehicle, markVehicleSeen
} = require("%enlist/vehicles/unseenVehicles.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { mkSpecialItemIcon } = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { vehDecorators } = require("%enlist/meta/profile.nut")
let { getVehSkins } = require("%enlSqGlob/vehDecorUtils.nut")
let { detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")

let DISABLED_ITEM = { tint = Color(40, 40, 40, 160), picSaturate = 0.0 }
let seenTanksList = Watched({})

let itemStatusIcon = @(vehicle) vehicle.status.flags & LOCKED ? statusIconLocked
  : null

let blinkIconUnseen = blinkUnseenIcon()
let noBlinkIconUnseen = noBlinkUnseenIcon()

let function mkUnseenSign(vehicle) {
  let vehicleTpl = vehicle?.basetpl
  let hasUnseenSign = Computed(@()
    unseenSquadsVehicle.value?[curSquad.value?.guid][vehicleTpl] ?? false)
  return function () {
  let res = { watch = hasUnseenSign }
  if (!hasUnseenSign.value)
    return res

  let unseenIcon = vehicleTpl not in seenTanksList.value ? blinkIconUnseen : noBlinkIconUnseen
  return res.__update({ children = unseenIcon })
}}

let setVehiclesSeen = @(vehicle) vehicle?.basetpl == null ? null
  : seenTanksList.mutate(@(v) v[vehicle.basetpl] <- true)

let mkVehicleName = @(vehicle, color) autoscrollText({
  text = getItemName(vehicle)
  textParams = { color }
})


let function mkVehicleImage(vehicleInfo, decor) {
  let override = {
    width = vehicleListCardSize[0] - smallPadding * 2
    height = vehicleListCardSize[1] - smallPadding * 2
    genOverride = {}
  }
  let { guid = "", gametemplate = "", isShopItem = false } = vehicleInfo
  if (gametemplate == "")
    return null

  if (guid != "") {
    let skinId = decor.findvalue(@(d) d.cType == "vehCamouflage" && d.vehGuid == guid)?.id
    if (skinId != null) {
      let skin = (getVehSkins(gametemplate) ?? []).findvalue(@(s) s.id == skinId)
      if ("objTexReplace" in skin)
        override.genOverride.objTexReplace <- skin.objTexReplace
    }
  }

  return iconByGameTemplate(gametemplate, override)?.__update(isShopItem ? DISABLED_ITEM : {})
}

let amountText = @(count, sf, isSelected) {
  rendObj = ROBJ_SOLID
  color = isSelected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_TEXT
    color = txtColor(sf, isSelected)
    text = loc("common/amountShort", { count })
  }.__update(sub_txt)
}

let itemCountRarity = @(item, sf, isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = [
    detailsStatusTier(item)
    1 >= (item?.count ?? 0) ? null : amountText(item.count, sf, isSelected)
  ]
}

let function card(item, onClick = @(_item) null, onDoubleClick = @(_item) null) {
  let isAllowed = (item.status.flags & CANT_USE) == 0
  let { isShowDebugOnly = false } = item
  let onHover = hoverHoldAction("unseenSoldierItem", item.basetpl,
    function(tpl) {
      if (unseenSquadsVehicle.value?[curSquad.value?.guid][tpl] && curSquadArmy.value)
        markVehicleSeen(curSquadArmy.value, tpl)
    })

  return watchElemState(function(sf) {
    let textColor = (sf & S_HOVER) || item == viewVehicle.value
      ? hoverTxtColor
      : defTxtColor
    let isSelected = item == viewVehicle.value
    let decorators = vehDecorators.value ?? {}
    return {
      watch = [viewVehicle, selectedVehicle, vehDecorators]
      behavior = Behaviors.Button
      rendObj = ROBJ_SOLID
      onClick = @() onClick(item)
      onDoubleClick = @() onDoubleClick(item)
      onHover
      onAttach = @() setVehiclesSeen(item)
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }

      color = isSelected ? activeBgColor
        : (sf & S_HOVER) ? hoverBgColor
        : isShowDebugOnly ? 0xFF003366
        : isAllowed ? defBgColor
        : blockedBgColor
      size = vehicleListCardSize
      padding = smallPadding
      children = [
        mkVehicleImage(item, decorators)
        {
          children = [
            mkUnseenSign(item)
            item == selectedVehicle.value
              ? statusIconChosen
              : itemStatusIcon(item)
          ]
        }
        {
          flow = FLOW_HORIZONTAL
          gap = hdpx(2)
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            mkSpecialItemIcon(item)
            mkVehicleName(item, textColor)
          ]
        }
        itemCountRarity(item, sf, isSelected)
      ]
    }
  })
}

return kwarg(card)