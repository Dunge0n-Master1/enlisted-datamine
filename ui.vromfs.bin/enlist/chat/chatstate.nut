from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let matching_api = require("matching.api")
let eventbus = require("eventbus")

let chatLogs = {}

let function getChatLog(chatId) {
  if (!(chatId in chatLogs)) {
    chatLogs[chatId] <- sharedWatched($"chat_{chatId}", @() [])
  }
  return chatLogs[chatId]
}

let function clearChatState(chatId) {
  if (chatId in chatLogs) {
    chatLogs[chatId].update([])
    // chatLogs is a 'cache' for sharedWatched
    // we can't remove keys from that cache unless they are not removable
    // in sharedWatched
    // delete chatLogs[chatId]
  }
}

let chat_handlers = {
  ["chat.chat_message"] = function(params) {
    let chatLog = getChatLog(params.chatId)
    chatLog.mutate(@(v) v.extend(params.messages))
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
