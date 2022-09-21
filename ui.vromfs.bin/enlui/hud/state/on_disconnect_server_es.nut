import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {switch_to_menu_scene} = require("app")
let {EventOnDisconnectedFromServer} = require("gameevents")
let net = require("net")
let msgbox = require("%ui/components/msgbox.nut")

let connErrMessages = {
  [net.DC_CONNECTION_CLOSED] = loc("ConnErr/CONNECTION_CLOSED"),
  [net.DC_CONNECTION_LOST] = loc("ConnErr/CONNECTION_LOST"),
  [net.DC_CONNECTION_STOPPED] = loc("ConnErr/CONNECTION_CLOSED"),
  [net.DC_CONNECTTION_ATTEMPT_FAILED] = loc("ConnErr/CONNECT_FAILED"),
  [net.DC_NET_PROTO_MISMATCH] = loc("ConnErr/CONNECT_FAILED_PROTO_MISMATCH"),
  [net.DC_SERVER_FULL] = loc("ConnErr/SERVER_FULL"),
  [net.DC_KICK_GENERIC] = loc("ConnErr/WAS_KICKED_OUT"),
  [net.DC_KICK_INACTIVITY] = loc("ConnErr/KICK_AFK"),
  [net.DC_KICK_ANTICHEAT] = loc("ConnErr/KICK_EAC"),
  [net.DC_KICK_FRIENDLY_FIRE] = loc("ConnErr/KICK_KILLING_TEAMMATES"),
  [net.DC_KICK_VOTE] = loc("ConnErr/DC_KICK_VOTE"),
}

let function onDisconnectedFromServer(evt, _eid, _comp) {
  let err_code = evt[0]
  let msgText = loc("network/disconnect_message").subst({
    err = connErrMessages?[err_code] ?? loc("ConnErr/UNKNOWN")
  })
  msgbox.show({
    text = msgText
    onClose = switch_to_menu_scene
  })
}

ecs.register_es("ui_disconnected_from_server_es", {
  [EventOnDisconnectedFromServer] = onDisconnectedFromServer,
})
