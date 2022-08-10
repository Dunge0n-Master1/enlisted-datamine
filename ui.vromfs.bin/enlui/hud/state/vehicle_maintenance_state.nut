import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_sync_time} = require("net")

let state = {
  isExtinguishing = Watched(false)
  isRepairing = Watched(false)
  maintenanceTime = Watched(0.0)
  maintenanceTotalTime = Watched(0.0)
  vehicleRepairTime = Watched(null)
  isRepairRequired = Watched(false)
  isExtinguishRequired = Watched(false)
  hasRepairKit = Watched(false)
  hasExtinguisher = Watched(false)
  canMaintainVehicle = Watched(false)
}

let maintenanceTargetQuery = ecs.SqQuery("maintenanceTargetQuery", {
  comps_ro = [
    ["repairable__repairTotalTime", ecs.TYPE_FLOAT, -1.0],
    ["repairable__repairTime", ecs.TYPE_FLOAT, -1.0],
    ["extinguishable__extinguishTotalTime", ecs.TYPE_FLOAT, -1.0],
    ["extinguishable__extinguishTime", ecs.TYPE_FLOAT, -1.0],
    ["extinguishable__inProgress", ecs.TYPE_BOOL, false],
    ["repairable__inProgress", ecs.TYPE_BOOL, false],
  ]
})
ecs.register_es("ui_maintenance_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let isHeroExtinguishing = comp["extinguisher__active"]
      let isHeroRepairing = comp["repair__active"]
      let mntTgtEid = comp["maintenance__target"]

      state.isExtinguishing(isHeroExtinguishing)
      state.isRepairing(isHeroRepairing)
      state.hasRepairKit(comp.repair__hasRepairKit)
      state.hasExtinguisher(comp.extinguisher__hasExtinguisher)
      state.canMaintainVehicle(comp.maintenance__canMaintainVehicle)
      if (mntTgtEid != INVALID_ENTITY_ID){
        state.isRepairRequired(comp.maintenance__targetNeedsRepair)
        state.isExtinguishRequired(comp.maintenance__targetNeedsExtinguishing)
        maintenanceTargetQuery.perform(mntTgtEid, function(_eid, comp){
          state.vehicleRepairTime((comp["repairable__inProgress"] && isHeroRepairing) ? comp["repairable__repairTime"] : null)
          if (comp["extinguishable__inProgress"] && isHeroExtinguishing) {
            state.maintenanceTime(comp["extinguishable__extinguishTime"] + get_sync_time())
            state.maintenanceTotalTime(comp["extinguishable__extinguishTotalTime"])
          } else if (comp["repairable__inProgress"] && isHeroRepairing) {
            state.maintenanceTime(comp["repairable__repairTime"] + get_sync_time())
            state.maintenanceTotalTime(comp["repairable__repairTotalTime"])
          } else {
            state.maintenanceTime(0.0)
            state.maintenanceTotalTime(0.0)
          }
        })
      } else {
        state.isRepairRequired(false)
        state.isExtinguishRequired(false)
        state.vehicleRepairTime(null)
        state.maintenanceTime(0.0)
        state.maintenanceTotalTime(0.0)
      }
    },
    function onDestroy(...){
      state.vehicleRepairTime(null)
      state.maintenanceTime(0.0)
      state.isRepairing(false)
      state.isExtinguishing(false)
      state.isRepairRequired(false)
      state.isExtinguishRequired(false)
      state.hasRepairKit(false)
      state.canMaintainVehicle(false)
    }
  },
  {
    comps_track = [
      ["maintenance__target", ecs.TYPE_EID],
      ["extinguisher__active", ecs.TYPE_BOOL, false],
      ["repair__active", ecs.TYPE_BOOL, false],
      ["repair__hasRepairKit", ecs.TYPE_BOOL, false],
      ["extinguisher__hasExtinguisher", ecs.TYPE_BOOL, false],
      ["maintenance__canMaintainVehicle", ecs.TYPE_BOOL, false],
      ["maintenance__targetNeedsRepair", ecs.TYPE_BOOL, false],
      ["maintenance__targetNeedsExtinguishing", ecs.TYPE_BOOL, false],
    ],
    comps_rq=["watchedByPlr"]
  }
)

return state