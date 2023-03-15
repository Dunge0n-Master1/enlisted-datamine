import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isTutorial = Watched(false)

ecs.register_es("tutorial_state_es", {
    onInit    = function(_evt, _eid, _comp) {
      isTutorial.update(true)
    }
    onDestroy = function(_evt, _eid, _comp) {
      isTutorial.update(false)
    }
  },
  { comps_rq = ["isTutorial"] }
)
return {
  isTutorial
}