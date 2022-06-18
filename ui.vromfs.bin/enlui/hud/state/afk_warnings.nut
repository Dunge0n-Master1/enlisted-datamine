import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {playerEvents} = require("%ui/hud/state/eventlog.nut")

ecs.register_es("afk_ui_es", {
  [ecs.sqEvents.AFKShowWarning] = @(_evt, _eid, _comp) playerEvents.pushEvent({text = loc("isAfkWarning"), ttl = 15}),
  [ecs.sqEvents.AFKShowDisconnectWarning] = @(_evt, _eid, _comp) playerEvents.pushEvent({text = loc("isKickedSoon"), ttl = 15})
}, { comps_rq=["player"] }, { tags="gameClient" })