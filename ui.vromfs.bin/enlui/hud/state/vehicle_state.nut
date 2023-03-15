import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

/*
//tag heroVehicle exists in vehicle controlled by players
//human_anim.vehicleSelected is eid in controlled human that shows vehicle that player is seated in
*/
let inVehicleDefValue = freeze({
  inTank = false
  inPlane = false
  inShip = false
  inGroundVehicle = false
  isVehicleAlive = false
  isVehicleCanBeRessuplied = false
  isPlaneOnCarrier = false
  vehicleResupplyType = ""
  controlledVehicleEid = ecs.INVALID_ENTITY_ID
})

let { inVehicleState, inVehicleStateSetValue } = mkFrameIncrementObservable(inVehicleDefValue, "inVehicleState")
let {
  inTank, inPlane, inShip, inGroundVehicle, isVehicleAlive, isVehicleCanBeRessuplied, isPlaneOnCarrier, vehicleResupplyType, controlledVehicleEid
} = watchedTable2TableOfWatched(inVehicleState)

let rolesDefValue = freeze({
  isDriver = false
  isGunner = false
  isPassenger = false
})

let { rolesState, rolesStateSetValue } = mkFrameIncrementObservable(rolesDefValue, "rolesState")
let rolesExport = watchedTable2TableOfWatched(rolesState)

let actionsDefValue = freeze({
  isPlayerCanEnter = true
  isPlayerCanExit = true
  isSafeToExit = true
  isHighSpeedWarningEnabled = false
})
let { actionsState, actionsStateSetValue } = mkFrameIncrementObservable(actionsDefValue, "actionsState")
let actionsExport = watchedTable2TableOfWatched(actionsState)

local lastInitedStateEid = ecs.INVALID_ENTITY_ID

ecs.register_es("ui_in_vehicle_eid_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      let inPlaneC = comp["airplane"] != null
      let inTankC = comp["isTank"] != null
      let inShipC = comp["ship"] != null
      let canBeRessuplied = comp.resupplyAtTime != null && comp.disableVehicleResupply == null
      inVehicleStateSetValue({
        inPlane=inPlaneC, inTank = inTankC, inShip=inShipC, inGroundVehicle=!inPlaneC,
        vehicleResupplyType = comp.vehicle_resupply__type
        isVehicleAlive = comp["isAlive"]
        isVehicleCanBeRessuplied = canBeRessuplied
        controlledVehicleEid = eid
        isPlaneOnCarrier = comp.plane_carrier_assist__isOnCarrier
      })
      lastInitedStateEid = eid
    },
    function onDestroy(eid, _){
      if (lastInitedStateEid == eid)
        inVehicleStateSetValue(inVehicleDefValue)
    }
  },
  {
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL, false],
      ["plane_carrier_assist__isOnCarrier", ecs.TYPE_BOOL, false],
    ],
    comps_ro = [
      ["airplane", ecs.TYPE_TAG, null],
      ["isTank", ecs.TYPE_TAG, null],
      ["ship", ecs.TYPE_TAG, null],
      ["vehicle_resupply__type", ecs.TYPE_STRING, ""],
      ["resupplyAtTime", ecs.TYPE_FLOAT, null],
      ["disableVehicleResupply", ecs.TYPE_TAG, null],
    ],
    comps_rq=["vehicleWithWatched"]
  }
)

ecs.register_es("ui_vehicle_role_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      if (comp["isInVehicle"])
        rolesStateSetValue({
          isDriver = comp["isDriver"]
          isGunner = comp["isGunner"]
          isPassenger = comp["isPassenger"]
        })
      else
        rolesStateSetValue(rolesDefValue)

    },
    function onDestroy() {
      rolesStateSetValue(rolesDefValue)
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
        actionsStateSetValue({
          isPlayerCanEnter = vehicleComp["vehicle__isPlayerCanEnter"]
          isPlayerCanExit = vehicleComp["vehicle__isPlayerCanExit"]
          isSafeToExit = vehicleComp["plane_view__tas"] < 1.0
          isHighSpeedWarningEnabled = vehicleComp["vehicle__isHighSpeedWarningEnabled"]
        })
      })
    },
    function onDestroy() {
      actionsStateSetValue(actionsDefValue)
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

return rolesExport.__merge(actionsExport, {
  inTank, inPlane, inShip, inGroundVehicle, isVehicleAlive, isVehicleCanBeRessuplied, isPlaneOnCarrier, controlledVehicleEid,
  vehicleResupplyType,
  inVehicle = Computed(@() inGroundVehicle.value || inPlane.value)
})