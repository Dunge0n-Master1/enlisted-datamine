import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isTutorial = mkWatched(persist, "isTutorial", false)

ecs.register_es("tutorial_state_es", {
    onInit    = @(_evt, _eid, _comp) isTutorial.update(true)
    onDestroy = @(_evt, _eid, _comp) isTutorial.update(false)
  },
  { comps_rq = ["isTutorial"] }
)
return {
  isTutorial
}