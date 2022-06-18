import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let vehicleUnderWaterEndTime = Watched(-1.0)
let vehicleUnderWaterMaxTime = Watched(-1.0)

let function trackVehicleUnderWater(_eid, comp){
  if (comp["underWaterStartTime"] > 0) {
    vehicleUnderWaterEndTime(comp["underWaterStartTime"] + comp["underWaterMaxTime"])
    vehicleUnderWaterMaxTime(comp["underWaterMaxTime"])
  }
  else
    vehicleUnderWaterEndTime(-1.0)
}

ecs.register_es("vehicleUnderWaterEndTimeEs",{
  [["onInit", "onChange"]] = trackVehicleUnderWater,
  onDestroy = @() vehicleUnderWaterEndTime(-1.0)
  }, {
    comps_track=[["underWaterStartTime",ecs.TYPE_FLOAT]]
    comps_ro = [["underWaterMaxTime",ecs.TYPE_FLOAT],["last_driver",ecs.TYPE_EID]]
    comps_rq = ["vehicleWithWatched"]
})

return {
  vehicleUnderWaterEndTime
  vehicleUnderWaterMaxTime
}
