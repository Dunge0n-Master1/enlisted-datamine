import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

/*
//tag heroVehicle exists in vehicle controlled by players
//human_anim.vehicleSelected is eid in controlled human that shows vehicle that player is seated in
*/

let inTank = Watched(false)
let inPlane = Watched(false)
let inShip = Watched(false)
let inGroundVehicle = Watched(false)
let isVehicleAlive = Watched(false)

let state = {
  isDriver = Watched(false)
  isGunner = Watched(false)
  isPassenger = Watched(false)
  isPlayerCanEnter = Watched(true)
  isPlayerCanExit = Watched(true)
  isSafeToExit = Watched(true)
  isHighSpeedWarningEnabled = Watched(false)

  controlledVehicleEid = Watched(INVALID_ENTITY_ID)
  inGroundVehicle = inGroundVehicle
  inPlane = inPlane
  inTank = inTank
  inShip = inShip
  isVehicleAlive = isVehicleAlive
}
state.inVehicle <- Computed(@() inGroundVehicle.value || inPlane.value)

ecs.register_es("ui_in_vehicle_eid_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      state.controlledVehicleEid(eid)
      let inPlaneC = comp["airplane"] != null
      let inTankC = comp["isTank"] != null
      let inShipC = comp["ship"] != null
      state.inPlane(inPlaneC)
      state.inGroundVehicle(!inPlaneC)
      state.inTank(inTankC)
      state.inShip(inShipC)

      state.isVehicleAlive(comp["isAlive"])
    },
    function onDestroy(){
      state.inPlane(false)
      state.inGroundVehicle(false)
      state.inTank(false)
      state.inShip(false)
      state.controlledVehicleEid(INVALID_ENTITY_ID)
      state.isVehicleAlive(false)
    }
  },
  {
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL, false],
    ],
    comps_ro = [
      ["airplane", ecs.TYPE_TAG, null],
      ["isTank", ecs.TYPE_TAG, null],
      ["ship", ecs.TYPE_TAG, null],
    ],
    comps_rq=["vehicleWithWatched"]
  }
)

ecs.register_es("ui_vehicle_role_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      state.isDriver(comp["isDriver"] && comp["isInVehicle"])
      state.isGunner(comp["isGunner"] && comp["isInVehicle"])
      state.isPassenger(comp["isPassenger"] && comp["isInVehicle"])
    },
    function onDestroy() {
      state.isDriver(false)
      state.isGunner(false)
      state.isPassenger(false)
    }
  },
  {
    comps_track = [
      ["isInVehicle", ecs.TYPE_BOOL, false],
      ["isDriver", ecs.TYPE_BOOL, false],
      ["isGunner", ecs.TYPE_BOOL, false],
      ["isPassenger", ecs.TYPE_BOOL, false]
    ],
    comps_rq = ["watchedByPlr"]
  }
)

let findUseEntityQuery = ecs.SqQuery("findUseEntityQuery", {comps_ro = [
  ["vehicle__isPlayerCanEnter", ecs.TYPE_BOOL, true],
  ["vehicle__isPlayerCanExit", ecs.TYPE_BOOL, true],
  ["plane_view__tas", ecs.TYPE_FLOAT, 0.0],
  ["vehicle__isHighSpeedWarningEnabled", ecs.TYPE_BOOL, false],
]})

ecs.register_es("ui_vehicle_state_es",
  {
    [["onChange", "onInit", "onUpdate"]] = function (_, comp) {
      findUseEntityQuery(comp.useActionEid, function(_, vehicleComp) {
        state.isPlayerCanEnter(vehicleComp["vehicle__isPlayerCanEnter"])
        state.isPlayerCanExit(vehicleComp["vehicle__isPlayerCanExit"])
        state.isSafeToExit(vehicleComp["plane_view__tas"] < 1.0)
        state.isHighSpeedWarningEnabled(vehicleComp.vehicle__isHighSpeedWarningEnabled)
      })
    },
    function onDestroy() {
      state.isPlayerCanEnter(true)
      state.isPlayerCanExit(true)
      state.isSafeToExit(true)
      state.isHighSpeedWarningEnabled(false)
    }
  },
  {
    comps_track = [
      ["useActionEid", ecs.TYPE_EID],
    ],
    comps_rq = ["watchedByPlr"]
  },
  { updateInterval = 0.5, before="*", after="*" }
)

return state