import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let tutorialZones = mkWatched(persist, "tutorialZones", {})
let function deleteEid(eid, state){
  if (eid in state.value)
    state.mutate(@(v) delete v[eid])
}

ecs.register_es("tutorial_zone_stats_ui_es",
  {
    [["onChange","onInit"]] = function(_evt, eid, comp) {
      if (comp["tutorial_zone__active"] == false) {
        deleteEid(eid, tutorialZones)
        return
      }

      tutorialZones.mutate(@(value) value[eid] <- comp)
    },
    function onDestroy(_evt, eid, _comp) {
      deleteEid(eid, tutorialZones)
    }
  },
  {
    comps_track = [["tutorial_zone__active", ecs.TYPE_BOOL]],
    comps_ro = [
      ["tutorial_zone__icon", ecs.TYPE_STRING, "waypoint"],
    ],
    comps_rq = ["tutorialZone"],
    comps_no = ["tutorial_zone__hideWaypoint"]
  }
)

return {
  tutorialZones = tutorialZones
}