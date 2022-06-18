from "%enlSqGlob/ui_library.nut" import *

let { matchingCall } = require("%enlist/matchingClient.nut")

let function createChat(cb = null) {
  matchingCall("chat.create_chat", cb)
}

let function joinChat(chatId, chatKey, cb = null) {
  matchingCall("chat.join_chat", cb, { chatId, chatKey })
}

let function leaveChat(chatId, cb = null) {
  matchingCall("chat.leave_chat", cb, { chatId })
}

let function sendMessage(chatId, text, cb = null) {
  matchingCall("chat.send_chat_message", cb, { chatId, message = { text } })
}

return {
  createChat
  joinChat
  leaveChat
  sendMessage
}
