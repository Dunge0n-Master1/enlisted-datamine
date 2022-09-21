import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { CmdShowHint } = require("dasevents")

ecs.register_es("cmd_show_hint_ui", // broadcast
  { [CmdShowHint] = function(evt, _eid, _comp) {
      playerEvents.pushEvent({event=evt.event, text=loc(evt.text), hotkey=evt.hotkey, unique=evt.unique, ttl=evt.ttl})
    }
  }, {}, { tags = "ui" }
)
