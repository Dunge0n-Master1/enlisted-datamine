import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let state = {
  downedEndTime = Watched(-1.0)
  alwaysAllowRevive = Watched(false)
  canBeRevivedByTeammates = Watched(false)
  canSelfReviveByHealing = Watched(false)
  canSelfReviveByPerk = Watched(false)
}

ecs.register_es("downedTracker",{
  [["onInit", "onChange"]] = function trackDownedState(_eid,comp) {
      foreach (k,v in state)
        v(comp[$"hitpoints__{k}"])
    },
  function onDestroy() {
    state.downedEndTime(-1.0)
    state.alwaysAllowRevive(false)
    state.canBeRevivedByTeammates(false)
    state.canSelfReviveByHealing(false)
    state.canSelfReviveByPerk(false)
  }
},
{
  comps_track = [
    ["hitpoints__downedEndTime",ecs.TYPE_FLOAT, -1],
    ["hitpoints__canSelfReviveByHealing", ecs.TYPE_BOOL, false],
    ["hitpoints__canSelfReviveByPerk", ecs.TYPE_BOOL, false],
    ["hitpoints__canBeRevivedByTeammates", ecs.TYPE_BOOL, false],
    ["hitpoints__alwaysAllowRevive", ecs.TYPE_BOOL, false],
  ],
  comps_rq=["watchedByPlr","isDowned"]
})

return state

