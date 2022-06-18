import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {playerEvents} = require("eventlog.nut")
let {CmdHeroLogEvent} = require("gameevents")
let {CmdLogEvent} = require("dasevents")

let function onCmdHeroLogEvent(evt, _eid, _comp){
  playerEvents.pushEvent({event=evt[0], text = loc(evt[1]), myTeamScores=false, sound=evt[2], ttl = evt[3] && evt[3] > 0 ? evt[3] : null})
}

let function onCmdLogDasEvent(evt, _eid, _comp){
  playerEvents.pushEvent({event=evt.event, text = loc(evt.text), myTeamScores=false, sound=evt.sound, ttl = evt.ttl > 0 ? evt.ttl : null})
}

ecs.register_es("cmd_hero_log_event_es",
  { [CmdHeroLogEvent] = onCmdHeroLogEvent },
  { comps_rq = ["hero"] }
)

ecs.register_es("cmd_hero_log_ex_event_es",
  { [ecs.sqEvents.CmdHeroLogExEvent] = function onCmdHeroLogExEvent(evt, _eid, _comp) {
      local eventData = evt.data
      if ("_requiresLocalization" in evt.data) {
        eventData = clone(evt.data)
        eventData["_requiresLocalization"].each(function(slot, key) {
          eventData[key] <- loc(slot, eventData)
        })
      }
      let e = {event=evt.data["_event"], text=loc(evt.data["_key"], eventData), myTeamScores=false}
      playerEvents.pushEvent(e)
    }
  },
  { comps_rq = ["hero"] }, {tags="gameClient"}
)

ecs.register_es("cmd_player_log_event_es",
  { [CmdHeroLogEvent] = function onCmdPlayerLogEvent(evt, eid, comp) {
      if (!comp.is_local)
        return
      onCmdHeroLogEvent(evt, eid, comp)
    },
    [CmdLogEvent] = function onCmdLogEvent(evt, eid, comp) {
      if (!comp.is_local)
        return
      onCmdLogDasEvent(evt, eid, comp)
    }
 },
  {comps_ro = [["is_local", ecs.TYPE_BOOL]], comps_rq = ["possessed"] }
)