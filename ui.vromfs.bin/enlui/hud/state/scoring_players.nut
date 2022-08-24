import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { state, stateSetKeyVal, stateDeleteKey } = mkFrameIncrementObservable({}, "state")
let { get_time_msec } = require("dagor.time")
let { scoreStatisticsComps, playerStatisticsFromComps } = require ("%enlSqGlob/scoreTableStatistics.nut")

ecs.register_es("scoring_players_ui_es",
  {
    [["onInit", "onChange"]]= @(_, eid, comp) stateSetKeyVal(eid, playerStatisticsFromComps(comp).__merge({
      lastUpdate = get_time_msec()
    }))
    onDestroy=@(_, eid, __) stateDeleteKey(eid)
  },
  {
    comps_track = scoreStatisticsComps
  }
)



return state
