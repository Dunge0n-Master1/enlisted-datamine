from "%enlSqGlob/ui_library.nut" import *

let { smallPadding, bigPadding, vehicleListCardSize, listCtors } = require("%enlSqGlob/ui/viewConst.nut")
let { txtColor, bgColor } = listCtors
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { statusTier, statusBadgeWarning } = require("%enlSqGlob/ui/itemPkg.nut")
let { txt, note, autoscrollText } = require("%enlSqGlob/ui/defcomps.nut")
let mkSpecialItemIcon = require("%enlSqGlob/ui/mkSpecialItemIcon.nut")
let { getVehSkins } = require("%enlSqGlob/vehDecorUtils.nut")


let hoverAddColor = Color(30,30,30,30)

let function mkVehicleImage(gametemplate, skinId) {
  let override = {
    width = vehicleListCardSize[0] - smallPadding * 2
    height = vehicleListCardSize[1] - smallPadding * 2
    genOverride = {}
  }
  if (skinId != null) {
    let skin = (getVehSkins(gametemplate) ?? []).findvalue(@(s) s.id == skinId)
    if ("objTexReplace" in skin)
      override.genOverride.objTexReplace <- skin.objTexReplace
  }

  return iconByGameTemplate(gametemplate, override)
}

let mkVehicleInfo = @(vehicleInfo, soldiersInSquad, sf) {
  vplace = ALIGN_TOP
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        mkSpecialItemIcon(vehicleInfo)
        autoscrollText({
          text = getItemName(vehicleInfo)
          textParams = { color = txtColor(sf) }
        })
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = statusTier(vehicleInfo)
        }
      ]
    }
    0 == (vehicleInfo?.crew ?? 0)
      ? null
      : note({
          text = " ".join([loc("vehicleDetails/crew"), $"{soldiersInSquad}/{vehicleInfo.crew}"])
          color = txtColor(sf)
        })
  ]
}

let mkNoVehicle = @(sf) {
  size = [flex(), vehicleListCardSize[1] - smallPadding * 2]
  children = [
    txt({
      hplace = ALIGN_CENTER
      text = loc("menu/vehicle/none")
      color = txtColor(sf)
    })
    statusBadgeWarning
  ]
}

let mkCurVehicle = @(
  vehicleInfo, soldiersList, openChooseVehicle = null, topRightChild = null,
  canSpawnOnVehicle = Watched(true)
) watchElemState(@(sf) {
    watch = [vehicleInfo, canSpawnOnVehicle, soldiersList]
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onClick = openChooseVehicle
    rendObj = ROBJ_SOLID
    color = canSpawnOnVehicle.value
      ? bgColor(sf)
      : bgColor(sf) + hoverAddColor
    padding = bigPadding
    children = (vehicleInfo.value?.gametemplate ?? "") == ""
      ? mkNoVehicle(sf)
      : [
          mkVehicleImage(vehicleInfo.value.gametemplate, vehicleInfo.value?.skin.id)
          {
            halign = ALIGN_RIGHT
            flow = FLOW_HORIZONTAL
            size = flex()
            children = [
              mkVehicleInfo(vehicleInfo.value, soldiersList.value.len(), sf)
              topRightChild
            ]
          }
        ]
  })

return kwarg(mkCurVehicle)