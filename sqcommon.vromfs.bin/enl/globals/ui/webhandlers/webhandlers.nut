let {exit_game} = require("app")
let {subscribe} = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { showMsgbox, removeMsgboxByUid } = require("%ui/components/msgbox.nut")
let eventbus = require("eventbus")

let handlers = {
  function show_message_box(_ev, params) {
    let { message = null, logout_on_close = false } = params
    if (message == null)
      return
    showMsgbox({
      uid = message
      text = message
      onClose = logout_on_close ? exit_game
        : @() eventbus.send_foreign("webHandlers.removeMsg", { message })
    })
  }
  replay_start = @(_ev, params) eventbus.send("replay.download", params)
}

subscribe("web-service", @(ev) handlers?[ev?.func](ev, ev?.params ?? {}))
eventbus.subscribe("webHandlers.removeMsg", @(msg) removeMsgboxByUid(msg.message))
