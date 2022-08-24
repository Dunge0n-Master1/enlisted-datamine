import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isPractice = Watched(false)

ecs.register_es("practice_state_es", {
    onInit    = @(_evt, _eid, _comp) isPractice(true)
    onDestroy = @(_evt, _eid, _comp) isPractice(false)
  },
  { comps_rq = ["isPractice"] }
)
return {
  isPractice
}