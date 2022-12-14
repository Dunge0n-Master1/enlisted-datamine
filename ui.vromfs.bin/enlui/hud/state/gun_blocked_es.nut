import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {playerEvents} = require("eventlog.nut")
let {EventOnGunBlocksShoot} = require("dasevents")

ecs.register_es("gun_blocked_es", {
  [EventOnGunBlocksShoot] = function(evt, _eid, _comp){
    playerEvents.pushEvent({event="gun_blocked", text = loc(evt.reason), myTeamScores=false})
  },
}, { comps_rq = ["hero"] }, {tags="gameClient"})
