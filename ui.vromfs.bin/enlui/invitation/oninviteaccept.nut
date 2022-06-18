from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%ui/components/msgbox.nut")
let eventbus = require("eventbus")

eventbus.subscribe("ipc.onInviteAccepted",  @(_) msgbox.show({
  text = loc("xbox/onInviteAccepted") //TODO: rename xbox key
  buttons = [
    { text = loc("Yes"),
      action = @() eventbus.send("ipc.onBattleExitAccept", null),
      isCurrent = true
    },
    { text = loc("No"), isCurrent = false, isCancel = true }
  ]
}))

return
