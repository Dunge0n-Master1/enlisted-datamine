import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isFreeFall = Watched(false)

ecs.register_es("free_fall_state_track_es",
  {
    [["onInit","onChange"]] = @(_eid, comp) isFreeFall(comp.human_freefall__isFreefall),
    [["onDestroy"]] = @(...) isFreeFall(false)
  },
  {
    comps_track = [["human_freefall__isFreefall", ecs.TYPE_BOOL]]
    comps_rq = ["hero"]
  }
)

return isFreeFall
