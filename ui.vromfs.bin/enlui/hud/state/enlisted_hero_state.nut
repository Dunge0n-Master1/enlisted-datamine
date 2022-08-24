import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isRadioMode = Watched(false)
let isThrowDistanceIncreased = Watched(false)

ecs.register_es("hero_state_radio_mode_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) isRadioMode(comp["human_weap__radioMode"])
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap__radioMode", ecs.TYPE_BOOL]]
  }
)

ecs.register_es("hero_state_throw_distance_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) isThrowDistanceIncreased(comp.entity_mods__grenadeThrowDistMult > 1.0)
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["entity_mods__grenadeThrowDistMult", ecs.TYPE_FLOAT]]
  }
)

return {
  isRadioMode
  isThrowDistanceIncreased
}