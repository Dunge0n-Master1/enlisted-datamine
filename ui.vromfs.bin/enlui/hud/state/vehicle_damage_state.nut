import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let state = {
  vehicleEngineBroken = Watched(false)
  vehicleTracksBroken = Watched(false)
  vehicleWheelsBroken = Watched(false)
  vehicleTransmissionBroken = Watched(false)
  vehicleTurretHorDriveBroken = Watched(false)
  vehicleTurretVerDriveBroken = Watched(false)
  vehiclePartDamaged = Watched(true)
}

local function partDamagedIndicate(partState, parts, dmState, partDestroyedCount = 0) {
  local isDamaged = false
  foreach (idx in (parts ?? [])) {
    if (dmState?[idx] == 0) {
      partDestroyedCount--
      if (partDestroyedCount <= 0) {
        isDamaged = true
        break
      }
    }
  }
  partState(isDamaged)
}

let turretHorDriveDmPartQuery = ecs.SqQuery("turretHorDriveDmPartQuery", {
  comps_ro = [["turret_drive_dm_part__horDriveDm", ecs.TYPE_INT, null]]
})
let getTurretHorDriveDmPart = @(eid) turretHorDriveDmPartQuery.perform(eid, @(_, comp) comp["turret_drive_dm_part__horDriveDm"])

let turretVerDriveDmPartQuery = ecs.SqQuery("turretVerDriveDmPartQuery", {
  comps_ro = [["turret_drive_dm_part__verDriveDm", ecs.TYPE_INT, null]]
})
let getTurretVerDriveDmPart = @(eid) turretVerDriveDmPartQuery.perform(eid, @(_, comp) comp["turret_drive_dm_part__verDriveDm"])

ecs.register_es("ui_vehicle_damage_state",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let wheelDestroyedCount = comp["vehicle__destroyedWheelsCountWarn"]

      let turretEids = comp["turret_control__gunEids"]?.getAll() ?? []
      let turretHorDriveParts = turretEids.map(getTurretHorDriveDmPart).filter(@(v) v != null)
      let turretVerDriveParts = turretEids.map(getTurretVerDriveDmPart).filter(@(v) v != null)
      partDamagedIndicate(state.vehicleEngineBroken, comp["dm_phys_parts__enginePartIds"]?.getAll(), comp.dm_state)
      partDamagedIndicate(state.vehicleTransmissionBroken, comp["dm_phys_parts__transmissionPartIds"]?.getAll(), comp.dm_state)
      partDamagedIndicate(state.vehicleTracksBroken, comp["dm_phys_parts__tracksPartIds"]?.getAll(), comp.dm_state)
      partDamagedIndicate(state.vehicleWheelsBroken, comp["dm_phys_parts__wheelsPartIds"]?.getAll(), comp.dm_state, wheelDestroyedCount)
      partDamagedIndicate(state.vehicleTurretHorDriveBroken, turretHorDriveParts, comp.dm_state)
      partDamagedIndicate(state.vehicleTurretVerDriveBroken, turretVerDriveParts, comp.dm_state)

      state.vehiclePartDamaged(comp["repairable__repairRequired"])
    },
    function onDestroy(){
      state.vehicleTracksBroken(false)
      state.vehicleWheelsBroken(false)
      state.vehiclePartDamaged(true)
      state.vehicleTransmissionBroken(false)
      state.vehicleEngineBroken(false)
      state.vehicleTurretHorDriveBroken(false)
      state.vehicleTurretVerDriveBroken(false)
    }
  },
  {
    comps_track = [
      ["dm_phys_parts__enginePartIds", ecs.TYPE_INT_LIST, null],
      ["dm_phys_parts__transmissionPartIds", ecs.TYPE_INT_LIST, null],
      ["dm_phys_parts__tracksPartIds", ecs.TYPE_INT_LIST, null],
      ["dm_phys_parts__wheelsPartIds", ecs.TYPE_INT_LIST, null],
      ["dm_state", ecs.TYPE_UINT16_LIST],
      ["repairable__repairRequired", ecs.TYPE_BOOL, false],
    ],
    comps_ro = [
      ["turret_control__gunEids", ecs.TYPE_EID_LIST, null],
      ["vehicle__destroyedWheelsCountWarn", ecs.TYPE_INT, 0],
    ],
    comps_rq=["vehicleWithWatched"]
  }
)

return state