from "%enlSqGlob/ui_library.nut" import *

let EventLogState = require("%ui/hud/state/eventlog_state.nut")
let AwardLogState = require("%ui/hud/state/awardlog_state.nut")
let { setIntervalForUpdateFunc } = require("%ui/helpers/timers.nut")

let instances = {
  playerEvents = EventLogState("playerEvents", 0.15, 3)
  awards = AwardLogState("awards")
  hints = EventLogState("hints", 0.15, 2)
}
instances.map(@(v) @(dt) v.update(dt))
  .each(@(updateFunc) setIntervalForUpdateFunc(0.45, updateFunc))

console_register_command(@(hotkey) instances.playerEvents.pushEvent({
    event = {}, text = $"hotkey sample: {hotkey}", hotkey, unique = "tutorial", ttl = 10
  }), "ui.add_player_hotkey")

console_register_command(@() instances.playerEvents.pushEvent({
    event = {}, text = $"block of hotkeys with two lines", unique = "tutorial", ttl = 10,
    hotkey = ["Vehicle.Steer", "Vehicle.Throttle", "Vehicle.Accel", "Vehicle.Brake", "Vehicle.HandBrake"]
  }), "ui.add_player_hotkeys_block")

console_register_command(@(text) instances.playerEvents.pushEvent({
    event = {}, text = text ?? "sample event"
  }), "ui.add_player_event")

return instances
