import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { EventOnSquadStats } = require("%enlSqGlob/sqevents.nut")
let awardsLog = require("%ui/hud/state/eventlog.nut").awards

let isAwardExists = @(name) loc($"hud/awards/{name}", "") != ""

let statAsAward = @(statName, statInfo) {
  type = statName
  score = statInfo.amount * statInfo.score
  forgiven = statInfo.amount < 0
  hasAward = isAwardExists(statName)
}
let getAwardsFromStats = @(stats) stats.reduce(@(res, statInfo, statName) res.append(statAsAward(statName, statInfo)), [])

ecs.register_es("add_player_score_awards_to_awardlog",
  {
    [EventOnSquadStats] = function(evt, _eid, comp) {
      if (comp.is_local)
        getAwardsFromStats(evt.data.stats).each(@(awardData)
          awardsLog.pushEvent({awardData}))
    }
  },
  {
    comps_ro = [["is_local", ecs.TYPE_BOOL]]
  },
  { tags="gameClient"}
)
