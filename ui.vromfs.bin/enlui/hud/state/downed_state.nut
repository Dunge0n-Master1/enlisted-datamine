import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { downedEndTime, downedEndTimeSetValue } = mkFrameIncrementObservable(-1.0, "downedEndTime")

ecs.register_es("downedTracker",{
  [["onInit", "onChange"]] = @(_, _eid, comp) downedEndTimeSetValue(comp.hitpoints__downedEndTime)
  onDestroy = @() downedEndTimeSetValue(-1.0)
},
{
  comps_track = [
    ["hitpoints__downedEndTime",ecs.TYPE_FLOAT, -1],
  ],
  comps_rq=["watchedByPlr","isDowned"]
})

return {downedEndTime}

