import "%dngscripts/ecs.nut" as ecs
let { loc } = require("dagor.localize")

let {playerEvents} = require("%ui/hud/state/eventlog.nut")

ecs.register_es("cmd_tutorial_hint_event_es",
  { [ecs.sqEvents.CmdTutorialHint] = function(evt, _eid, _comp) {
      let data = evt.data
      playerEvents.pushEvent({event=data["event"], unique=data["unique"], text=loc(data["text"]), hotkey=data["hotkey"], ttl=data["ttl"]})
    }
  },
  { comps_rq = ["player"] },
  { tags = "gameClient" }
)
