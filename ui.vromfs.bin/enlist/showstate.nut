import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { curCamera } = require("%enlist/sceneWithCamera.nut")
let { curSoldierGuid } = require("%enlist/soldiers/model/squadInfoState.nut")
let { curVehicle, objInfoByGuid } = require("%enlist/soldiers/model/state.nut")
let { viewVehicle } = require("%enlist/vehicles/vehiclesListState.nut")
let { viewItem } = require("%enlist/soldiers/model/selectItemState.nut")
let {
  isCustomizationWndOpened
} = require("%enlist/soldiers/soldierCustomizationState.nut")
let { vehDecorators } = require("%enlist/meta/profile.nut")
let { getVehSkins } = require("%enlSqGlob/vehDecorUtils.nut")


let curHoveredItem = mkWatched(persist, "curHoveredItem")
let curHoveredSoldier = mkWatched(persist,"curHoveredSoldier")
let curSelectedItem = mkWatched(persist,"curSelectedItem")

let itemInArmory = Computed(function() {
  let item = viewItem.value ?? curSelectedItem.value
  return item?.itemtype != "vehicle" ? item?.gametemplate : null
})

let currentNewItem = Computed(@() curSelectedItem.value?.itemtype == "soldier" ? null : curSelectedItem.value?.gametemplate)
let currentNewSoldierGuid = Computed(@() curSelectedItem.value?.itemtype == "soldier" ? curSelectedItem.value?.guid : null)

let soldierInSoldiers = Computed(@() curCamera.value == "new_items" ? currentNewSoldierGuid.value : curSoldierGuid.value)

let vehicleInVehiclesScene = Computed(@() curSelectedItem.value
  ?? viewVehicle.value
  ?? objInfoByGuid.value?[curVehicle.value]
)

let vehTplInVehiclesScene = Computed(@() vehicleInVehiclesScene.value?.gametemplate)

let vehDataInVehiclesScene = Computed(function() {
  let { guid = null, gametemplate = null} = vehicleInVehiclesScene.value
  if (guid == null || gametemplate == null)
    return null

  let res = {}
  let skinId = vehDecorators.value
    .findvalue(@(d) d.cType == "vehCamouflage" && d.vehGuid == guid)?.id
  if (skinId != null) {
    let camouflageData = getVehSkins(gametemplate).findvalue(@(s) s.id == skinId)
    if (camouflageData != null) {
      res.vehCamouflage <- camouflageData.objTexReplace
      res.objTexSet <- camouflageData?.animchar__objTexSet
    }
  }

  return res
})

let function isAircraft(template) {
  if (template == null)
    return false
  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  return templ?.getCompValNullable("airplane") != null
}

let scene = Computed(function() {
  let curCameraValue = curCamera.value
  if (curCameraValue == "vehicles" || curSelectedItem.value?.itemtype == "vehicle")
    return isAircraft(vehTplInVehiclesScene.value) ? "aircrafts" : "vehicles"
  return curCameraValue == "soldiers" && !curSoldierGuid.value ? "squad"
    : isCustomizationWndOpened.value ? "soldier_customization"
    : curCameraValue == "new_items" && currentNewSoldierGuid.value ? "soldier_in_middle"
    : curCameraValue
})

return {
  currentNewItem
  curHoveredItem
  curHoveredSoldier
  curSelectedItem
  vehTplInVehiclesScene
  vehDataInVehiclesScene
  itemInArmory
  soldierInSoldiers
  scene
}