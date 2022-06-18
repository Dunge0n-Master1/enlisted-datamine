import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { DBGLEVEL } = require("dagor.system")
let { Point2, Point3 } = require("dagor.math")
let {
  vehTplInVehiclesScene, vehDataInVehiclesScene,
  itemInArmory, soldierInSoldiers, currentNewItem, scene
} = require("%enlist/showState.nut")
let { curCampItems } = require("%enlist/soldiers/model/state.nut")
let { curSquadSoldiersReady } = require("%enlist/soldiers/model/readySoldiers.nut")
let {
  selectedSquadSoldiers, selSquadVehicleGameTpl
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let {EventLevelLoaded} = require("gameevents")
let { soldierViewGen, createSoldier, appearanceToRender} = require("soldier_tools.nut")
let { createVehicle } = require("vehicle_tools.nut")
let { doFadeBlack, registerFadeBlackActions } = require("%enlist/fadeToBlack.nut")
let transformItem = require("transformItem.nut")
let { setDmViewerTarget } = require("%enlist/vehicles/dmViewer.nut")
let { setDecalTarget } = require("%enlist/vehicles/decorViewer.nut")
let { viewVehDecorators } = require("%enlist/vehicles/customizeState.nut")
let { selectVehParams } = require("%enlist/vehicles/vehiclesListState.nut")
let { soldiersLook } = require("%enlist/meta/servProfile.nut")
let { allOutfitByArmy } = require("%enlist/soldiers/model/config/outfitConfig.nut")


let composedScene = Computed(@() selectedSquadSoldiers.value ? "squad" : scene.value)

/*
  TODO:
  - rework:
    - create scene and resources by scene + what to watch in watch and how. to make possible creation of vehicle + squad, as well
  - we want to show weapon \ weapon mods if weapon is selected or we want to choose new weapon
  ? if you are wating too long and not touching mouse\keyboard\gamepad - start scenic cameras
  - scenic cameras should start not from first, but random one
*/

//!----- quick and dirty set cameras ---
let setCameraQuery = ecs.SqQuery("setCameraQuery", {
  comps_rw = [
    ["transform", ecs.TYPE_MATRIX],
    ["fov", ecs.TYPE_FLOAT],
    ["menu_cam__target", ecs.TYPE_EID],
    ["menu_cam__dirInited", ecs.TYPE_BOOL],
    ["menu_cam__initialDir", ecs.TYPE_POINT3],
    ["menu_cam__offset", ecs.TYPE_POINT3],
    ["menu_cam__offsetMult", ecs.TYPE_POINT3],
    ["menu_cam__limitYaw", ecs.TYPE_POINT2],
    ["menu_cam__limitPitch", ecs.TYPE_POINT2],
    ["menu_cam__shouldRotateTarget", ecs.TYPE_BOOL],
  ],
  comps_rq = ["camera__active"], comps_no=["scene"]})
let setDofQuery = ecs.SqQuery("setDofQuery", {comps_rw = [["post_fx", ecs.TYPE_OBJECT]]})
let findScenicCamQuery = ecs.SqQuery("findScenicCamQuery", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["fov", ecs.TYPE_FLOAT],
    ["menu_cam__target", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["menu_cam__offset", ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
    ["menu_cam__offsetMult", ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
    ["menu_cam__limitYaw", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["menu_cam__limitPitch", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["menu_cam__shouldRotateTarget", ecs.TYPE_BOOL, false],
    ["scene", ecs.TYPE_STRING]
  ]})
let findScenicDofDistQuery = ecs.SqQuery("findScenicDofDistQuery", {comps_ro = [
    ["dof__on", ecs.TYPE_BOOL],
    ["scene", ecs.TYPE_STRING],
    ["dof__nearDofStart", ecs.TYPE_FLOAT],
    ["dof__nearDofEnd", ecs.TYPE_FLOAT],
    ["dof__nearDofAmountPercent", ecs.TYPE_FLOAT],
    ["dof__farDofStart", ecs.TYPE_FLOAT],
    ["dof__farDofEnd", ecs.TYPE_FLOAT],
    ["dof__farDofAmountPercent", ecs.TYPE_FLOAT],
  ]})

let function setDofDist(dof_comp){
  setDofQuery.perform(function(_eid, post_fx_comp){
    post_fx_comp.post_fx["dof__on"] = dof_comp["dof__on"]
    post_fx_comp.post_fx["dof__nearDofStart"] = dof_comp["dof__nearDofStart"]
    post_fx_comp.post_fx["dof__nearDofEnd"] = dof_comp["dof__nearDofEnd"]
    post_fx_comp.post_fx["dof__nearDofAmountPercent"] = dof_comp["dof__nearDofAmountPercent"]
    post_fx_comp.post_fx["dof__farDofStart"] = dof_comp["dof__farDofStart"]
    post_fx_comp.post_fx["dof__farDofEnd"] = dof_comp["dof__farDofEnd"]
    post_fx_comp.post_fx["dof__farDofAmountPercent"] = dof_comp["dof__farDofAmountPercent"]
  })
}

let function setCamera(cameraComps){
  setCameraQuery.perform(function(_eid, comp){
    foreach (k, v in cameraComps)
      if (k in comp)
        comp[k] = v
  })
}


//!----- quick and dirty create entities for preview ---

local function createEntity(template, transform, callback = null, extraTemplates=[]){
  if (template) {
    template = "+".join([template].extend(extraTemplates))
    return ecs.g_entity_mgr.createEntity(template, { transform = transform }, callback)
  }
  return INVALID_ENTITY_ID
}

let logg = DBGLEVEL !=0 ? log_for_user : log.log
let function makeWeaponTemplate(template){
  if (template == null || template == "")
    return null

  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  local itemTemplate = templ?.getCompValNullable("item__template")
    ?? templ?.getCompValNullable("ammo_holder__templateName")
  if (itemTemplate==null){
    if (templ?.getCompValNullable("animchar__res") != null)
      itemTemplate = template
    else {
      logg("Incorrect template found for weapon meta-template:", template)
      return null
    }
  }
  return ecs.makeTemplate({
    baseTemplate = itemTemplate ?? template, addTemplates = ["item_in_world", "menu_item"]
  })
}

let function setCameraTargetInScene(newScene, targetEid){
  if (composedScene.value != newScene)
    return
  setCamera({["menu_cam__target"] = targetEid})
}

let function setDmViewerInScene(newScene, targetEid){
  if (composedScene.value != newScene)
    return
  setDmViewerTarget(targetEid)
}

let function setDecalTargetInScene(newScene, targetEid){
  if (composedScene.value != newScene)
    return
  setDecalTarget(targetEid)
}

let function resetCameraDirection(){
  setCamera({["menu_cam__dirInited"] = false})
}

let cameraTarget = mkWatched(persist, "cameraTarget", INVALID_ENTITY_ID)
let isFadeDone = mkWatched(persist, "isFadeDone", false)

let visibleScene = Watched(composedScene.value)

let function recreateStubFunc(...){
  logg("Incorrect recreate cb function")
}

let function makeShowScene(sceneDesc, name){
  let {
    compName, watch, transformItemFunc = transformItem,
    createEntityFunc = createEntity, reInitEntityFunc = recreateStubFunc,
    shouldResetCameraDirection = Watched(false),
    recreateSoldier = false
  } = sceneDesc
  let query = ecs.SqQuery($"query{compName}", {
    comps_ro = [["transform", ecs.TYPE_MATRIX]]
    comps_rw = [compName]
  })
  let visibleWatch = Computed(@() visibleScene.value == name ? watch.value : null)
  let isSceneFading = Computed(@() visibleScene.value == name && !isFadeDone.value)
  let function updateEntity(...) {
    let data = visibleWatch.value
    if (isSceneFading.value)
      return
    let function update(_baseEid, comp){
      if (!recreateSoldier || comp[compName] == INVALID_ENTITY_ID) {
        ecs.g_entity_mgr.destroyEntity(comp[compName])
        comp[compName] = createEntityFunc(data, transformItemFunc(comp["transform"], data))
      }
      else {
        let newSoldierEid = reInitEntityFunc(data, transformItemFunc(comp["transform"], data), null, comp[compName])
        if (newSoldierEid != INVALID_ENTITY_ID)
          comp[compName] = newSoldierEid
      }

      cameraTarget(comp[compName])
      if (shouldResetCameraDirection.value)
        resetCameraDirection()
    }
    query.perform(update)
  }
  let showScene = sceneDesc.__merge({
    visibleWatch
    isSceneFading
    query
    updateEntity
  })
  visibleWatch.subscribe(updateEntity)
  isSceneFading.subscribe(updateEntity)
  shouldResetCameraDirection.subscribe(updateEntity)
  let subscribeFunc = @(_) visibleScene.value == name ? updateEntity() : null
  foreach (w in (showScene?.slaveWatches ?? []))
    w.subscribe(subscribeFunc)
  return showScene
}


let objectsToObserve = {
  soldiers = {
    compName = "menu_char_to_control",
    createEntityFunc = @(guid, transform, callback = null)
      createSoldier({ guid, transform, callback, soldiersLook = soldiersLook.value,
        premiumItems = allOutfitByArmy.value })
    watch = soldierInSoldiers
    slaveWatches = [curCampItems, soldierViewGen, soldiersLook, allOutfitByArmy]
  },
  soldier_customization = {
    compName = "menu_char_to_control",
    recreateSoldier = true
    createEntityFunc = @(guid, transform, callback = null)
      createSoldier({
        guid,
        transform,
        callback,
        soldiersLook = soldiersLook.value
        premiumItems = allOutfitByArmy.value
        customizationOvr = appearanceToRender.value })
    reInitEntityFunc = @(guid, transform, callback = null, reInitEid = INVALID_ENTITY_ID)
      createSoldier({
        guid,
        transform,
        callback,
        soldiersLook = soldiersLook.value
        premiumItems = allOutfitByArmy.value
        customizationOvr = appearanceToRender.value,
        reInitEid})
    watch = soldierInSoldiers
    slaveWatches = [curCampItems, soldierViewGen, appearanceToRender, soldiersLook, allOutfitByArmy]
  },
  soldier_in_middle = {
    compName = "menu_char_to_control",
    createEntityFunc = @(guid, transform, callback = null)
      createSoldier({ guid, transform, callback, soldiersLook = soldiersLook.value isDisarmed = true })
    watch = soldierInSoldiers
    slaveWatches = [curCampItems, soldierViewGen, soldiersLook, allOutfitByArmy]
  },
  vehicles = {
    compName = "menu_vehicle_to_control",
    createEntityFunc = @(template, transform, callback = null)
      createVehicle({
        template, transform, callback,
        customazation = viewVehDecorators.value
      })
    transformItemFunc = @(transform, ...) transform
    watch = vehTplInVehiclesScene
    slaveWatches = [viewVehDecorators]
    shouldResetCameraDirection = Computed(@()
      !(selectVehParams.value?.isCustomMode ?? false))
  },
  aircrafts = {
    compName = "menu_aircraft_to_control",
    transformItemFunc = @(transform, ...) transform
    watch = vehTplInVehiclesScene
    shouldResetCameraDirection = Watched(true)
  },
  armory = {
    compName = "menu_weapon_to_control",
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback)
    watch = itemInArmory
    shouldResetCameraDirection = Watched(true)
  },
  new_items = {
    compName = "menu_new_items_to_control",
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback)
    watch = currentNewItem
    shouldResetCameraDirection = Watched(true)
  },
  battle_pass = {
    compName = "menu_battle_pass_to_control",
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback)
    watch = currentNewItem
    shouldResetCameraDirection = Watched(true)
  }
}.map(makeShowScene)

let function updateSceneObjects(...) {
  if (!isFadeDone.value)
    return

  setCameraTargetInScene(composedScene.value, cameraTarget.value)
  setDmViewerInScene(composedScene.value, cameraTarget.value)
  setDecalTargetInScene(composedScene.value, cameraTarget.value)
}

foreach (v in [cameraTarget, isFadeDone, composedScene])
  v.subscribe(updateSceneObjects)

registerFadeBlackActions({
  change_camera = kwarg(function(cameraComps, curScene) {
    setCamera(cameraComps)
    updateSceneObjects()
    visibleScene(curScene)
    findScenicDofDistQuery.perform(@(_dof_eid, dof_comp) dof_comp.scene == curScene ? setDofDist(dof_comp) : null)
    isFadeDone(true)
  })
})

let function processScene(...) {
  let curScene = composedScene.value
  if (!curScene)
    return
  isFadeDone(false)
  local cameraNotFound = true
  findScenicCamQuery.perform(function(_eid,comp) {
    if (comp.scene != curScene)
      return
    cameraNotFound = false
    let cameraComps = {
      ["menu_cam__dirInited"] = false,
      ["menu_cam__initialDir"] = comp.transform.getcol(2),
    }
    foreach (k, v in comp)
      cameraComps[k] <- v
    doFadeBlack({ fadein = 0.33, fadeout = 0.4, action = "change_camera",
      params = { cameraComps, curScene } })
  })
  if (cameraNotFound)
    isFadeDone(true)
}
composedScene.subscribe(processScene)

let gettransforms = @(query) ecs.query_map(query, @(_eid, comp) {
    transform = comp["transform"]
    order = comp["priority_order"]
  })
  .sort(@(a, b) a.order <=> b.order)

let destroyEntityByQuery = @(query) query.perform(@(eid, _comp)
  ecs.g_entity_mgr.destroyEntity(eid))

/*
  background objects in squads
  todo:
   - add animated cameras
*/

local lastShownSquadToPlace = []
let currentSquadToPlace = Computed(function() {
  local newSquad = selectedSquadSoldiers.value
  if (!newSquad && soldierInSoldiers.value)
    return null

  newSquad = newSquad ?? curSquadSoldiersReady.value
  if (newSquad.len() != 0 && !isEqual(lastShownSquadToPlace, newSquad))
    lastShownSquadToPlace = newSquad
  return lastShownSquadToPlace
})
let vehicleToPlace = Computed(function() {
  let vehicle = selectedSquadSoldiers.value
    ? selSquadVehicleGameTpl.value
    : vehTplInVehiclesScene.value
  return vehicle ? [vehicle] : null
})

let createdSoldiers = mkWatched(persist, "createdSoldiers", [])
let squadPlacesQuery = ecs.SqQuery("squadPlaces", {
  comps_ro = ["transform", ["priority_order", ecs.TYPE_INT, 0]]
  comps_rq = ["menu_soldier_respawnbase"]
})
let menuBackgroundSoldiersQuery = ecs.SqQuery("menuBackgroundSoldiersQuery", {
  comps_rq = ["background_menu_soldier"]
})

let createdVehicles = mkWatched(persist, "createdVehicles", [])
let vehiclesPlacesQuery = ecs.SqQuery("vehiclePlaces", {
  comps_ro = ["transform", ["priority_order", ecs.TYPE_INT, 0]]
  comps_rq = ["menu_vehicle_respawnbase"]
})
let menuBackgroundVehiclesQuery = ecs.SqQuery("menuVehiclesPlacesQuery", {
  comps_rq = ["background_menu_vehicle"]
})
//we duplicate state of created objects by creating with tag and store it in script.
//While it is enough to have it only in script it is not enough to have it in entities, because createEntity is Async and if state is changed in a one frame twice
//objects of first change will be not destroyed (they do not have tags). We can replace to createEntitySync, but this is not reponsive enough
// we can also create entitySync with just tag and than recreate it with tag+all other. That would work will look strange in code

let mkReplaceObjectsFunc = @(placesQuery, objectsQuery, createFunc, createdList)
  function replaceObjects(objects) {
    createdList.value.each(@(eid) ecs.g_entity_mgr.destroyEntity(eid))
    destroyEntityByQuery(objectsQuery)
    if (objects == null)
      return
    let places = gettransforms(placesQuery)
    createdList(objects
      .slice(0, min(places.len(), objects.len()))
      .map(@(obj, i) createFunc(obj, places[i])))
  }

let replaceSoldiers = mkReplaceObjectsFunc(squadPlacesQuery,
  menuBackgroundSoldiersQuery,
  @(object, place) createSoldier({
    guid = object?.guid
    transform = place.transform
    order = place.order
    soldiersLook = soldiersLook.value
    premiumItems = allOutfitByArmy.value
    extraTemplates = ["background_menu_soldier"]
  }),
  createdSoldiers)

let replaceVehicles = mkReplaceObjectsFunc(
  vehiclesPlacesQuery,
  menuBackgroundVehiclesQuery,
  @(object, place) createVehicle({
    template = object
    transform = place.transform
    customazation = vehDataInVehiclesScene.value
  }),
  createdVehicles
)

registerFadeBlackActions({
  replace_soldiers = @() replaceSoldiers(currentSquadToPlace.value)
  replace_vehicles = @() replaceVehicles(vehicleToPlace.value)
})

let currentSquadToPlaceReplace = @(...)
  doFadeBlack({fadein=0.2, fadeout=0.6, action = "replace_soldiers" })
let vehicleToPlaceReplace = @(...)
  doFadeBlack({fadein=0.2, fadeout=0.3, action = "replace_vehicles" })

currentSquadToPlace.subscribe(currentSquadToPlaceReplace)
vehicleToPlace.subscribe(vehicleToPlaceReplace)

//trigger on level loaded
ecs.register_es("setscene_es", {
    [EventLevelLoaded] = function(_evt, _eid, _comp) {
      processScene()
      objectsToObserve.each(@(v) v.updateEntity())
      currentSquadToPlaceReplace()
      vehicleToPlaceReplace()
   }
})

