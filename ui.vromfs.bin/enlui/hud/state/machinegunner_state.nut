import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isMachinegunner = Watched(false)

ecs.register_es("machinegunner_track_es",
  {
    [["onInit","onChange"]] = @(_eid,comp) isMachinegunner(comp["human_attached_gun__isAttached"])
    onDestroy = @(...) isMachinegunner(false)
  },
  {comps_track=[["human_attached_gun__isAttached", ecs.TYPE_BOOL]]
   comps_rq = ["hero"]})

return isMachinegunner
