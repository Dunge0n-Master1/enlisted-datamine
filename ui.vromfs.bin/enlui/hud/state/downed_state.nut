import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let defValue = freeze({
  downedEndTime = -1.0
  canSelfReviveByHealing = false
})
let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")
let { downedEndTime, canSelfReviveByHealing } = watchedTable2TableOfWatched(state)

ecs.register_es("downedTracker",{
  [["onInit", "onChange"]] = function trackDownedState(_, _eid, comp) {
      stateSetValue(defValue.map(@(_, k) comp[$"hitpoints__{k}"]))
    },
  onDestroy = @() stateSetValue(defValue)
},
{
  comps_track = [
    ["hitpoints__downedEndTime",ecs.TYPE_FLOAT, -1],
    ["hitpoints__canSelfReviveByHealing", ecs.TYPE_BOOL, false],
  ],
  comps_rq=["watchedByPlr","isDowned"]
})

return {downedEndTime, canSelfReviveByHealing}

