from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let textInput = require("%ui/components/textInput.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let textButton = require("%ui/components/textButton.nut")
let {getChatLog} = require("chatState.nut")
let {sendMessage} = require("chatApi.nut")
let {format_unixtime} = require("dagor.time")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")

let ColorInactive = Color(120,120,120)
let function messageInLog(entry) {
  let fmtString = "%H:%M:%S"
  return {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = $"[{format_unixtime(fmtString, entry.timestamp)}] {remap_nick(entry.sender.name)}: {entry.text}"
    key = entry.timestamp
    margin = fsh(0.5)
    size = [flex(), SIZE_TO_CONTENT]
  }.__update(fontSub)
}


let function chatRoom(chatId) {
  if (chatId == null)
    return null

  let chatMessage = Watched("")


  let scrollHandler = ScrollHandler()


  let function doSendMessage() {
    if (chatMessage.value=="")
      return
    sendMessage(chatId, chatMessage.value)
    chatMessage.update("")
  }


  let function chatInputField() {
    let options = {
      placeholder = loc("chat/inputPlaceholder")
      margin = 0
      onReturn = doSendMessage
    }.__update(fontSub)
    return {
      size = [flex(), SIZE_TO_CONTENT]
      children = textInput(chatMessage, options)
    }
  }


  let function chatInput() {
    return {
      flow = FLOW_HORIZONTAL
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_BOTTOM
      gap = fsh(1)
      padding = [fsh(1), 0, 0, 0]

      children = [
        chatInputField
        {
          valign = ALIGN_BOTTOM
          size = [SIZE_TO_CONTENT, flex()]
          halign = ALIGN_RIGHT
          children = textButton(loc("chat/sendBtn"), doSendMessage, {margin=0}.__update(fontSub))
        }
      ]
    }
  }

  local lastScrolledTo = null

  let function logContent() {
    let chatLog = getChatLog(chatId)?.data
    if (chatLog == null)
      return {}
    let messages = chatLog.value.map(messageInLog)
    let scrollTo = chatLog.value.len() ? chatLog.value.top().timestamp : null

    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.RecalcHandler

      watch = chatLog

      children = messages

      onRecalcLayout = function(_initial) {
        if (scrollTo && scrollTo != lastScrolledTo) {
          lastScrolledTo = scrollTo
          scrollHandler.scrollToChildren(@(desc) ("key" in desc) && (desc.key == scrollTo), 2, false, true)
        }
      }
    }
  }


  let function chatLog() {
    return {
      size = flex()

      rendObj = ROBJ_FRAME
      color = ColorInactive
      borderWidth = [2, 0]
      padding = [2, 0]

      children = scrollbar.makeVertScroll(logContent, {scrollHandler = scrollHandler})
    }
  }

  return function () {
    if (!getChatLog(chatId))
      return {}

    return {
      size = flex()
      flow = FLOW_VERTICAL
      stopMouse = true

      children = [
        chatLog
        chatInput
      ]
    }
  }
}


return chatRoom
