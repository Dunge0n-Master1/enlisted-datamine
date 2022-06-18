import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventLevelLoaded} = require("gameevents")
let {playerEvents} = require("%ui/hud/state/eventlog.nut")

ecs.register_es("hints_ui_es",
  {
    [EventLevelLoaded] = function (_evt, eid, comp) {
      let ttl = comp["hint__ttl"]
      let msg = comp["hint__message"]
      ecs.set_callback_timer(function() {
        playerEvents.pushEvent({text = loc(msg), ttl = ttl})
        ecs.g_entity_mgr.destroyEntity(eid)
      }, comp["hint__showTimeout"], false)
    }
  },
  { comps_ro=[["hint__message", ecs.TYPE_STRING], ["hint__showTimeout", ecs.TYPE_FLOAT], ["hint__ttl", ecs.TYPE_FLOAT]] },
  { tags="gameClient" })