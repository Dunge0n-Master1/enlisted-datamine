import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {startswith} = require("string")
let {playerEvents} = require("eventlog.nut")
let {secondsToStringLoc} = require("%ui/helpers/time.nut")
let {CmdHeroLogEvent, CmdLogEvent, CmdHeroLogExEvent} = require("dasevents")

let function onCmdHeroLogEvent(evt, _eid, _comp){
  playerEvents.pushEvent({event=evt.event, text = loc(evt.text), myTeamScores=false, sound=evt.sound, ttl = evt.ttl > 0 ? evt.ttl : null})
}

let function onCmdLogDasEvent(evt){
  local eventData = clone(evt.data.getAll())
  evt.data.getAll().each(function(slot, key) {
    if (startswith(key, "_requiresTime/"))
      eventData[key] <- secondsToStringLoc(slot)
    else if (typeof(slot)=="string")
      eventData[key] <- loc(slot, eventData)
  })
  playerEvents.pushEvent({event=evt.event, text = loc(evt.text, eventData), myTeamScores=false, sound=evt.sound, ttl = evt.ttl > 0 ? evt.ttl : null})
}

ecs.register_es("cmd_hero_log_event_es",
  { [CmdHeroLogEvent] = onCmdHeroLogEvent },
  { comps_rq = ["hero"] }
)

ecs.register_es("cmd_hero_log_ex_event_es",
  { [CmdHeroLogExEvent] = function onCmdHeroLogExEvent(evt, _eid, _comp) {
      local eventData = clone(evt.data.getAll())
      evt.data.getAll().each(function(slot, key) {
        if (startswith(key, "_requiresTime/"))
          eventData[key] <- secondsToStringLoc(slot)
        else if (typeof(slot)=="string")
          eventData[key] <- loc(slot, eventData)
      })
      let e = {event=evt.event, text=loc(evt.key, eventData), myTeamScores=false}
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
    [CmdLogEvent] = function onCmdLogEvent(evt, _eid, comp) {
      if (!comp.is_local)
        return
      onCmdLogDasEvent(evt)
    }
 },
  {comps_ro = [["is_local", ecs.TYPE_BOOL]], comps_rq = ["possessed"] }
)