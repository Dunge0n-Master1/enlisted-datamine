import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { curCamera } = require("%enlist/sceneWithCamera.nut")
let { curSection, mainSectionId } = require("%enlist/mainMenu/sectionsState.nut")
let { curSoldierGuid } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { curVehicle, objInfoByGuid, getSoldierItemSlots } = require("%enlist/soldiers/model/state.nut")
let { viewVehicle, selectVehParams } = require("%enlist/vehicles/vehiclesListState.nut")
let { viewItem } = require("%enlist/soldiers/model/selectItemState.nut")
let {
  isCustomizationWndOpened
} = require("%enlist/soldiers/soldierCustomizationState.nut")
let {
  selectedSquadSoldiers
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let { vehDecorators, campItemsByLink } = require("%enlist/meta/profile.nut")
let { selectedCampaign } = require("%enlist/meta/curCampaign.nut")
let { getVehSkins } = require("%enlSqGlob/vehDecorUtils.nut")
let { itemTypesInSlots } = require("%enlist/soldiers/model/all_items_templates.nut")


let curHoveredItem = mkWatched(persist, "curHoveredItem")
let curHoveredSoldier = mkWatched(persist,"curHoveredSoldier")
let curSelectedItem = mkWatched(persist,"curSelectedItem")
let cameraScenes = mkWatched(persist, "cameraScenes", [])

let cameraFovDelta = Watched(0)
let function changeCameraFov(delta, minDelta = 0, maxDelta = 0) {
  cameraFovDelta(clamp(cameraFovDelta.value + delta, minDelta, maxDelta))
}

let isVehicleSceneVisible = Computed(function() {
  let { armyId = null, squadId = null } = selectVehParams.value
  return armyId != null && squadId != null
})

let itemInArmory = Computed(function() {
  let item = viewItem.value ?? curSelectedItem.value
  return item?.itemtype != "vehicle" ? item?.gametemplate : null
})
let itemInArmoryAttachments = Computed(function(){
  let res = []
  let item = (viewItem.value ?? curSelectedItem.value)
  let guid = item?.guid
  if (guid != null)
    foreach (data in getSoldierItemSlots(guid, campItemsByLink.value)) {
      let tpl = data.item?.basetpl
      if (tpl != null)
        res.append(tpl)
    }
  return res
})

let typeWithNormalCameraAngle = {
  medbox = true
  building_tool = true
}

let needWeaponCameraAngle = Computed(function() {
  let { itemtype = null } = viewItem.value ?? curSelectedItem.value
  return itemtype in (itemTypesInSlots.value?.mainWeapon ?? {})
    && itemtype not in typeWithNormalCameraAngle
})

let currentNewItem = Computed(@() curSelectedItem.value?.itemtype == "soldier" ? null : curSelectedItem.value?.gametemplate)
let currentNewItemAttachments = Computed(function(){
  let equipScheme = curSelectedItem.value?.equipScheme
  let res = []
  if(equipScheme != null)
    foreach(slot in equipScheme)
      foreach(item in (slot?.items ?? [])){
        if(item != null)
          res.append(item)
      }
  return res
})

let currentNewSoldierGuid = Computed(@() curSelectedItem.value?.itemtype == "soldier" ? curSelectedItem.value?.guid : null)

let soldierInSoldiers = Computed(@() curCamera.value == "new_items" ? currentNewSoldierGuid.value : curSoldierGuid.value)

let vehicleInVehiclesScene = Computed(@()
  (curSelectedItem.value?.itemtype == "vehicle" ? curSelectedItem.value : null)
  ?? viewVehicle.value
  ?? objInfoByGuid.value?[curVehicle.value])

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

let function getAircraftInfo(template) {
  if (template == null)
    return { isAircraft = false, isFloating = false, isBike = false }

  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  return {
    isAircraft = templ?.getCompValNullable("airplane") != null
    isFloating = templ?.getCompValNullable("floating_aircraft") != null
    isBike = templ?.getCompValNullable("bike") != null
  }
}

let squadCampaignVehicleFilter = Computed(function() {
  let { isAircraft, isFloating, isBike } = getAircraftInfo(vehTplInVehiclesScene.value)
  // plane scene is the same for all campaigns and differs only for floating/non floating planes for now
  return isBike ? "bike"
    : isFloating ? "plane_floating"
    : isAircraft ? "plane"
    : selectedCampaign.value
})

let sceneCameraSquadFilter = Computed(function() {
  let prefix = curSection.value == mainSectionId ? "main_menu" : "squad"
  let sceneName = $"{prefix}_{squadCampaignVehicleFilter.value}"
  // to support old spawns with no difference betwee campaigns
  // we can remove system below and cameraScenes watched after old menu is no longer used
  return cameraScenes.value.contains(sceneName) ? sceneName : prefix
})

ecs.register_es("add_scene_camera_es", {
    onInit = function(_eid, comp) {
      cameraScenes.mutate(@(val) val.append(comp.scene))
    }
    onDestroy = function(_eid, comp) {
      let idx = cameraScenes.value.indexof(comp.scene)
      if (idx != null)
        cameraScenes.mutate(@(val) val.remove(idx))
    }
  }, { comps_ro = [["scene", ecs.TYPE_STRING]] }
)

let scene = Computed(function() {
  let curCameraValue = curCamera.value
  if (curCameraValue == "vehicles" || curSelectedItem.value?.itemtype == "vehicle") {
    let aircraftInfo = getAircraftInfo(vehTplInVehiclesScene.value)
    return !aircraftInfo.isAircraft ? "vehicles"
      : aircraftInfo.isFloating ? "aircrafts_floating"
      : "aircrafts"
  }
  return (curCameraValue == "soldiers" && !curSoldierGuid.value) || selectedSquadSoldiers.value ? sceneCameraSquadFilter.value
    : isCustomizationWndOpened.value ? "soldier_customization"
    : curCameraValue == "new_items" && currentNewSoldierGuid.value ? "soldier_in_middle"
    : curCameraValue
})

return {
  currentNewItem
  currentNewItemAttachments
  curHoveredItem
  curHoveredSoldier
  curSelectedItem
  vehTplInVehiclesScene
  vehDataInVehiclesScene
  itemInArmory
  itemInArmoryAttachments
  needWeaponCameraAngle
  soldierInSoldiers
  scene
  squadCampaignVehicleFilter
  vehicleInVehiclesScene
  isVehicleSceneVisible
  cameraFovDelta
  changeCameraFov
}
