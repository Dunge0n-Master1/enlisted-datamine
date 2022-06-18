import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isRepairFortification = Watched(false)
let repairFortificationEndTime = Watched(0.0)
let repairFortificationTimeTotal = Watched(0.0)

ecs.register_es("ui_fortification_repair_es",
  {
    [["onChange", "onInit"]] = function (_evt, _eid, comp) {
      let isActive = comp["fortification_repair__active"]
      isRepairFortification(isActive)
      if (isActive) {
        repairFortificationTimeTotal(comp["fortification_repair__time"])
        repairFortificationEndTime(comp["fortification_repair__timer"])
      }
    },
    function onDestroy(...) {
      isRepairFortification(false)
    }
  },
  {
    comps_track = [
      ["fortification_repair__active", ecs.TYPE_BOOL]
    ],
    comps_rq=["watchedByPlr"],
    comps_ro=[
      ["fortification_repair__timer", ecs.TYPE_FLOAT],
      ["fortification_repair__time", ecs.TYPE_FLOAT],
    ],
  }
)

return {
  isRepairFortification
  repairFortificationEndTime
  repairFortificationTimeTotal
}