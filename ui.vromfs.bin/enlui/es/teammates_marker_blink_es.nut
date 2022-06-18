import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

ecs.register_es("teammates_marker_blink_es",
  {
    [["onChange","onInit"]] = function(_evt, eid, comp) {
      let trigger = $"blink_marker_start_{eid}"
      if (comp["marker__blink"])
        anim_start(trigger)
      else
        anim_request_stop(trigger)
    }
  },
  { comps_track = [["marker__blink", ecs.TYPE_BOOL]], comps_rq = ["possessedByPlr"] }
)
