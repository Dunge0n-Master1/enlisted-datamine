import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {playerEvents} = require("eventlog.nut")
let {EventOnGunBlocksShoot} = require("gameevents")

ecs.register_es("gun_blocked_es", {
  [EventOnGunBlocksShoot] = function onGunBlocked(evt, _eid, _comp){
    let reason = evt[0]
    playerEvents.pushEvent({event="gun_blocked", text = loc(reason), myTeamScores=false})
  },
}, { comps_rq = ["hero"] }, {tags="gameClient"})

