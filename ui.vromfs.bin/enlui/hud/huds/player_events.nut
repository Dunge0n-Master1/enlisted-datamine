from "%enlSqGlob/ui_library.nut" import *

let {playerEvents} = require("%ui/hud/state/eventlog.nut")
let {makeItem} = require("mkPlayerEvents.nut")
let {minimalistHud} = require("%ui/hud/state/hudOptionsState.nut")
let {forcedMinimalHud} = require("%ui/hud/state/hudGameModes.nut")

let isMinimalHud = Computed(@() forcedMinimalHud.value || minimalistHud.value)

let showMinHudEvents = {
  building_cannot_confirm_by_enemy = true
  building_blocked_too_close_to_respawns = true
  building_blocked_too_close_to_capture_points = true
  building_cannot_confirm_when_objects_in = true
  building_blocked_underwater = true
  building_gun_not_attachable = true
  building_blocked_restricted_zone = true
}

let function playerEventsRoot() {
  let events = isMinimalHud.value
    ? playerEvents.events.value.filter(@(event) event?.event in showMinHudEvents)
    : playerEvents.events.value
  return {
    flow   = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    size   = [pw(80), SIZE_TO_CONTENT]
    watch = [playerEvents.events, isMinimalHud]
    children = events.map(makeItem)
  }
}


return playerEventsRoot
