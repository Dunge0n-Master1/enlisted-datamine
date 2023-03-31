import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

local lastInitedStateEid = ecs.INVALID_ENTITY_ID
let vehicleSteerTips = Watched([])
let steerTipDuration = Watched(15.0)

ecs.register_es("ui_vehicle_steer_tips",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      lastInitedStateEid = eid
      vehicleSteerTips(comp.vehicle__steerTips.getAll())
      steerTipDuration(comp.vehicle__steerTipDuration)
    },
    function onDestroy(eid, _) {
      if (lastInitedStateEid == eid)
        vehicleSteerTips([])
    }
  },
  {
    comps_ro = [["vehicle__steerTipDuration", ecs.TYPE_FLOAT, 15.0]]
    comps_track = [["vehicle__steerTips", ecs.TYPE_STRING_LIST]],
    comps_rq=["vehicleWithWatched", "hasVehicleControl"]
  }
)

return {
  vehicleSteerTips
  steerTipDuration
}
