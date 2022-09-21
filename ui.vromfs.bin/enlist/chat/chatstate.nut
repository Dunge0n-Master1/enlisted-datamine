from "%enlSqGlob/ui_library.nut" import *

let {globalWatched} = require("%dngscripts/globalState.nut")
let matching_api = require("matching.api")
let eventbus = require("eventbus")

let chatLogs = {}

let function getChatLog(chatId) {
  if (!(chatId in chatLogs)) {
    let key = $"chat_{chatId}"
    let w = globalWatched(key, @() [])
    chatLogs[chatId] <- {data = w[key], update = w[$"{key}Update"]}
  }
  return chatLogs[chatId]
}

let function clearChatState(chatId) {
  if (chatId in chatLogs) {
    chatLogs[chatId].update([])
    // chatLogs is a 'cache' for globalWatched
    // we can't remove keys from that cache unless they are not removable
    // in globalWatched
    // delete chatLogs[chatId]
  }
}

let chat_handlers = {
  ["chat.chat_message"] = function(params) {
    let chatLog = getChatLog(params.chatId)
    chatLog.update([].extend(chatLog.data.value, params.messages))
  },
  ["chat.user_joined"] = function(params) {
    log($"{params.user.name} joined chat")
  },
  ["chat.user_leaved"] = function(params) {
    log($"{params.user.name} leaved from chat")
  }
}

let function subscribeHandlers() {
  foreach (k, v in chat_handlers) {
    matching_api.listen_notify(k)
    eventbus.subscribe(k, v)
  }
}

return {
  getChatLog
  clearChatState
  subscribeHandlers
}
