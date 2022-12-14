import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {inTank, isPassenger} = require("%ui/hud/state/vehicle_state.nut")
let {isHoldingGunPassenger} = require("%ui/hud/state/hero_in_vehicle_state.nut")
let {get_gun_template_by_props_id} = require("dm")
let {EventOnSeatOwnersChanged} = require("dasevents")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { vehicleTurrets, vehicleTurretsSetValue } = mkFrameIncrementObservable([], "vehicleTurrets")

let { turretsReload, turretsReloadSetKeyVal, turretsReloadDeleteKey } = mkFrameIncrementObservable({}, "turretsReload")
let { turretsAmmo, turretsAmmoSetValue, turretsAmmoModify } = mkFrameIncrementObservable({}, "turretsAmmo")
let { mainTurretEid, mainTurretEidSetValue } = mkFrameIncrementObservable(ecs.INVALID_ENTITY_ID, "mainTurretEid")
let { currentMainTurretEid, currentMainTurretEidSetValue } = mkFrameIncrementObservable(ecs.INVALID_ENTITY_ID, "currentMainTurretEid")
const MACHINE_GUN_TRIGGER = 2

let function resetState() {
  vehicleTurretsSetValue([])
  turretsAmmoSetValue([])
}

let turretQuery = ecs.SqQuery("turretQuery", {
  comps_ro=[
    ["gun__propsId", ecs.TYPE_INT, -1],
    ["gun__reloadable", ecs.TYPE_BOOL, false],
    ["turret__groupName", ecs.TYPE_STRING, ""],
    ["turretInput", ecs.TYPE_TAG, null],
    ["turret_input__isLocalControlLocked", ecs.TYPE_BOOL, false],
    ["currentBulletId", ecs.TYPE_INT, 0],
    ["nextBulletId", ecs.TYPE_INT, -1],
    ["turret__triggerGroup", ecs.TYPE_INT, -1],
    ["gun__ammoSetsInfo", ecs.TYPE_SHARED_ARRAY, null],
    ["gun__shellsAmmo", ecs.TYPE_ARRAY, []],
    ["turret__disableAim", ecs.TYPE_TAG, null]
  ]
})

let function get_trigger_mappings(hotkeys) {
  let mappings = {}
  foreach (mapping in hotkeys) {
    let name = mapping?.name
    let hotkey = mapping?.hotkey
    if (name != null && hotkey != null)
      mappings[name] <- hotkey
  }
  return mappings
}
let getGunTmpl = memoize(@(propsId) ecs.g_entity_mgr.getTemplateDB().getTemplateByName(get_gun_template_by_props_id(propsId) ?? ""))
let getAmmoSets = @(_, comp)
  (comp["gun__ammoSetsInfo"]?.getAll() ?? []).map(@(set, setInd) { name=set?[0]?.name ?? "", type=set?[0]?.type ?? "", maxAmmo = comp["gun__shellsAmmo"]?[setInd] ?? 0 })

let function initTurretsState(comp, ignore_control_turret_eid = ecs.INVALID_ENTITY_ID) {
  let turretsByGroup = {}

  let triggerMappingComp = comp["turret_control__triggerMapping"]?.getAll() ?? []
  let triggerMappings = get_trigger_mappings(triggerMappingComp)
  let turretInfo = comp["turret_control__turretInfo"]

  foreach (gunIndex, gunEid in comp["turret_control__gunEids"]) turretQuery.perform(gunEid, function(v,gunComp) {
    let gunPropsId = gunComp["gun__propsId"]
    let gunTpl = getGunTmpl(gunPropsId)
    let trigger = turretInfo?[gunIndex]?.trigger

    let turret = {
      gunEid
      gunPropsId
      name = gunTpl?.getCompValNullable("item__name")
      currentAmmoSetId = gunComp["currentBulletId"]
      nextAmmoSetId = gunComp["nextBulletId"]
      isReloadable = gunComp["gun__reloadable"]
      icon = gunTpl?.getCompValNullable("gun__icon")
      isControlled = gunComp["turretInput"] != null && gunEid != ignore_control_turret_eid
      isLocalControlLocked = gunComp["turret_input__isLocalControlLocked"]
      isBomb = trigger == "bombs"
      isRocket = trigger == "rockets"
      hotkey = triggerMappings?[trigger]
      triggerGroup = gunComp["turret__triggerGroup"]
      groupName = gunComp["turret__groupName"]
      isWithSeveralShells = gunComp["nextBulletId"] != -1
      ammoSet = getAmmoSets(v, gunComp)
      showCrosshair = gunComp.turret__disableAim == null
    }
    let groupName = turret.groupName
    if (turretsByGroup?[groupName] == null)
      turretsByGroup[groupName] <- []
    turretsByGroup[groupName].append(turret)
  })

  let turrets = []
  foreach (group, turretsInGroup in turretsByGroup)
    if (group != "") {
      let mainTurretInGroup = turretsInGroup[0]
      if (mainTurretInGroup.isBomb || mainTurretInGroup.isRocket)
        mainTurretInGroup.namesInGroup <-
          turretsInGroup.reduce(function(res, turret) { res[turret.gunEid] <- turret.name; return res }, {})
      turrets.append(mainTurretInGroup)
    } else
      turrets.extend(turretsInGroup)

  let mainTurretEidValue = (turretsByGroup?[""][0] ?? turrets[0]).gunEid ?? ecs.INVALID_ENTITY_ID
  mainTurretEidSetValue(mainTurretEidValue)
  currentMainTurretEidSetValue(
    turretsByGroup?[""].findvalue(@(turret) turret.isControlled && turret.triggerGroup != MACHINE_GUN_TRIGGER)?.gunEid ?? mainTurretEidValue)

  vehicleTurretsSetValue(turrets)
  let ammoState = comp["ui_turrets_state__ammo"]
  let turretEids = turrets.reduce(function(res, turret) { res[turret.gunEid] <- null; return res }, {})
  let turretGroups = turretsByGroup.map(@(_) null).filter(@(_, group) group != "")
  let ammoKeys = turretEids.__merge(turretGroups)
  turretsAmmoSetValue(ammoKeys.map(@(_, key) ammoState?[key.tostring()].getAll() ?? {}))
}

ecs.register_es("vehicle_turret_state_ui_es",
  {
    [["onInit", "onChange", EventOnSeatOwnersChanged]] = @(_, comp) initTurretsState(comp),
    onDestroy = @(...) resetState(),
  },
  {
    comps_ro = [
      ["ui_turrets_state__ammo", ecs.TYPE_OBJECT, null],
      ["turret_control__triggerMapping", ecs.TYPE_SHARED_ARRAY, null],
      ["turret_control__turretInfo", ecs.TYPE_SHARED_ARRAY],
    ]
    comps_track = [
      ["turret_control__isInputLocked", ecs.TYPE_BOOL],
      ["turret_control__gunEids", ecs.TYPE_EID_LIST],
      ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST],
    ]
    comps_rq = ["vehicleWithWatched"]
  }
)

ecs.register_es("turret_ammo_ui_es",
  { [["onInit", "onChange"]] = function(_, comp) {
      let turrets_state = comp["ui_turrets_state__ammo"].getAll()
      turretsAmmoModify(@(prevVal) prevVal.map(@(_, key) turrets_state?[key.tostring()]))
    }
  },
  {
    comps_track = [["ui_turrets_state__ammo", ecs.TYPE_OBJECT]]
    comps_rq = ["vehicleWithWatched"]
  })

let turretsVehicleQuery = ecs.SqQuery("turretsVehicleQuery", {
  comps_ro = [
    ["ui_turrets_state__ammo", ecs.TYPE_OBJECT, null],
    ["turret_control__triggerMapping", ecs.TYPE_SHARED_ARRAY, null],
    ["turret_control__turretInfo", ecs.TYPE_SHARED_ARRAY],
    ["turret_control__gunEids", ecs.TYPE_EID_LIST],
    ["vehicle_seats__seatEids", ecs.TYPE_EID_LIST],
  ],
  comps_rq = ["vehicleWithWatched"]
})

ecs.register_es("track_controlled_turret_ui_es",
  { [["onInit", "onChange"]] = function(_eid, comp) {
      turretsVehicleQuery(comp["turret__owner"], @(_, vehicleComp) initTurretsState(vehicleComp))
    },
    onDestroy = function(deleted_eid, comp) {
      turretsVehicleQuery(comp.turret__owner, @(_, vehicleComp) initTurretsState(vehicleComp, deleted_eid))
    }
  },
  {
    comps_track = [
      ["currentBulletId", ecs.TYPE_INT, 0],
      ["nextBulletId", ecs.TYPE_INT, 0],
    ]
    comps_ro = [["turret__owner", ecs.TYPE_EID]]
    comps_rq = ["turretInput"]
  }
)

ecs.register_es("turret_state_reload_progress_ui",
  { [["onInit", "onChange"]] = function(_, eid, comp) {
      turretsReloadSetKeyVal(eid, {
        reloadTimeMult = comp.ui_turret_reload_progress__reloadTimeMult
        progressStopped = comp["ui_turret_reload_progress__progressStopped"]
        endTime = comp["ui_turret_reload_progress__finishTime"]
        totalTime = comp["ui_turret_reload_progress__finishTime"] - comp["ui_turret_reload_progress__startTime"]
      })
    },
    onDestroy = @(_, eid, _comp) turretsReloadDeleteKey(eid)
  },
  { comps_track = [
    ["ui_turret_reload_progress__startTime", ecs.TYPE_FLOAT],
    ["ui_turret_reload_progress__finishTime", ecs.TYPE_FLOAT],
    ["ui_turret_reload_progress__progressStopped", ecs.TYPE_FLOAT, -1],
    ["ui_turret_reload_progress__reloadTimeMult", ecs.TYPE_FLOAT, 1.]
  ],
    comps_rq = ["isTurret", "turretInput"]
  },
  {tags="ui"}
)

let showVehicleWeapons = Computed(function() {
  let haveTurrets = (vehicleTurrets.value?.len() ?? 0) > 0
  return (inTank.value ? haveTurrets && !isPassenger.value : haveTurrets) && !isHoldingGunPassenger.value
})

let mainTurretAmmo = Computed(@() turretsAmmo.value?[mainTurretEid.value])
let currentMainTurretAmmo = Computed(@() turretsAmmo.value?[currentMainTurretEid.value])

return {
  vehicleTurrets
  showVehicleWeapons
  mainTurretEid
  currentMainTurretEid
  currentMainTurretAmmo
  turretsReload
  turretsAmmo
  mainTurretAmmo
}
