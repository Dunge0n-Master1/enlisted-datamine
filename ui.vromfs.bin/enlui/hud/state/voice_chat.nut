from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")

let speakingPlayers = mkWatched(persist, "speakingPlayers", {})
let order = persist("order", @() { val = 0 })

let function onSpeakingStatus(who, is_speaking) {
  if (is_speaking) {
    if (who in speakingPlayers.value)
      return
    speakingPlayers.mutate(@(v) v[who] <- order.val++)
  }
  else {
    if (!(who in speakingPlayers.value))
      return
    speakingPlayers.mutate(@(v) delete v[who])
  }
}

eventbus.subscribe("voice.show_speaking", @(name) onSpeakingStatus(name, true))
eventbus.subscribe("voice.hide_speaking",  @(name) onSpeakingStatus(name, false))
eventbus.subscribe("voice.reset_speaking",  @(_) speakingPlayers({}))

//console_register_command(@(name, state) onSpeakingStatus(name, state),
//                         $"voice.display_speaking_player")

return speakingPlayers
