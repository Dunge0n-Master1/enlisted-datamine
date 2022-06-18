import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isRadioMode = mkWatched(persist, "isRadioMode", false)

ecs.register_es("hero_state_radio_mode_es",
  {
    [["onInit", "onChange"]] = @(_eid, comp) isRadioMode(comp["human_weap__radioMode"])
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap__radioMode", ecs.TYPE_BOOL]]
  }
)

return {
  isRadioMode = isRadioMode
}