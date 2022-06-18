import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let function sendChatMsg(params) { //should be some enum
  let evt = ecs.event.CmdChatMessage(params)
  ecs.client_msg_sink(evt)
}

let function sendQuickChatSoundMsg(text, qmsg = null, sound = null) {
  sendChatMsg({mode = "qteam", text = text, qmsg = qmsg, sound = sound})
}

let function sendQuickChatItemMsg(text, item_name=null) {
  sendChatMsg({mode="qteam", text = text, qmsg={item=item_name}})
}

let function sendItemHint(item_name, item_eid, item_count, item_owner_nickname) {
  sendChatMsg({mode="qteam", text= "squad/item_hint", qmsg={item=item_name, count = item_count, nickname = item_owner_nickname}, eid = item_eid/*, showOnMap = true*/})
}

return {
  sendQuickChatSoundMsg
  sendQuickChatMsg = sendQuickChatItemMsg
  sendQuickChatItemMsg = sendQuickChatItemMsg
  sendItemHint = sendItemHint
}