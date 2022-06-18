import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let state = mkWatched(persist, "players", {})
let { get_time_msec } = require("dagor.time")
let { scoreStatisticsComps, playerStatisticsFromComps } = require ("%enlSqGlob/scoreTableStatistics.nut")

let trackComponents = @(_evt, eid, comp)
  state.mutate(@(value) value[eid] <- playerStatisticsFromComps(comp).__merge({
    lastUpdate = get_time_msec()
  }))

let function onDestroy(_evt, eid, _comp) {
  state.mutate(function(value) {
    delete value[eid]
  })
}



ecs.register_es("scoring_players_ui_es",
  {
    onInit=trackComponents
    onDestroy=onDestroy
    onChange=trackComponents
  },
  {
    comps_track = scoreStatisticsComps
  }
)



return state
