from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { TEAM_UNASSIGNED } = require("team")
let scrollbar = require("%ui/components/scrollbar.nut")
let {CONTROL_BG_COLOR, TEAM1_TEXT_COLOR, TEAM0_TEXT_COLOR} = require("style.nut")
let chatState = require("state/chat.nut")
let {setInteractiveElement} = require("state/interactive_state.nut")
let {localPlayerTeam, localPlayerName} = require("state/local_player.nut")
let { DBGLEVEL } = require("dagor.system")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let JB = require("%ui/control/gui_buttons.nut")
let {sound_play_one_shot} = require("sound")
let {UserNameColor} = require("%ui/style/colors.nut")
let msgbox = require("%ui/components/msgbox.nut")

let switchSendModesAllowed = DBGLEVEL > 0

let showChatInput = mkWatched(persist, "showChatInput", false)

let inputBoxHeight = fsh(8)
let systemMessageColor = Color(225,35,35)

let itemTextAnim = [
//  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.2, play=true, easing=OutCubic }
//  { prop=AnimProp.opacity, from=0.5, to=1, duration=0.2, play=true}
//  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], duration=0.4, playFadeOut=true}
]

let itemGap = {size=[0,hdpx(1)]}

let itemAnim = [
  { prop=AnimProp.opacity, from=1.0, to=0, duration=0.6, playFadeOut=true}
  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], delay=0.4, duration=0.6, playFadeOut=true}
]

let function chatItem(item, params = {}) {
  let color = item?.send_mode == "system" ? systemMessageColor
    : item.team == TEAM_UNASSIGNED ? 0xFFFFFFFF
    : item.team == localPlayerTeam.value ? TEAM0_TEXT_COLOR
    : TEAM1_TEXT_COLOR

  let rowChildren = []
  if (item.name != "")
    rowChildren.append(
      item.sendMode != "all" ? null
        : { rendObj = ROBJ_TEXT, color = color, text = $"[{loc("chat/all")}]" }
      {
        rendObj = ROBJ_TEXT,
        color = item.name == localPlayerName.value ? UserNameColor : color,
        text = $"{remap_others(item.name)}: "
      })
  rowChildren.append({
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color
    text = item.text
  })

  return {
    size = [flex(), SIZE_TO_CONTENT]
    key = item
    rendObj = ROBJ_WORLD_BLUR
    color = Color(200,200,200,200)
    children = {
      flow = FLOW_HORIZONTAL
      key = item
      transform = { pivot = [0, 1.0] }
      size = [flex(), SIZE_TO_CONTENT]
      animations = (params?.noanim) ? null : itemTextAnim
      children = rowChildren
    }
    transform = { pivot = [0, 0] }
    animations = (params?.noanim) ? null :itemAnim
  }
}

local lastScrolledTo = null
let scrollHandler = ScrollHandler()

let function chatLogContent() {
  let logLines = chatState.logState.value.map(@(line) chatItem(line, { noanim = true }))
  let scrollTo = chatState.logState.value.len() ? chatState.logState.value.top() : null
  return {
    watch = chatState.logState
    key = "chatLog"
    size = [flex(),SIZE_TO_CONTENT]
    minHeight = SIZE_TO_CONTENT
    clipChildren = true
    gap = itemGap
    flow = FLOW_VERTICAL
    children = logLines
    behavior = Behaviors.RecalcHandler
    onRecalcLayout = function(_initial) {
      if (scrollTo && scrollTo != lastScrolledTo) {
        lastScrolledTo = scrollTo
        scrollHandler.scrollToChildren(@(desc) ("key" in desc) && (desc.key == scrollTo), 2, false, true)
      }
    }
  }
}

let chatLog = {
  size = [flex(), flex()]
  flow = FLOW_VERTICAL
  children = scrollbar.makeVertScroll(chatLogContent, {scrollHandler = scrollHandler})
  vplace = ALIGN_BOTTOM
}

let function chatContent() {
  let children = chatState.lines.value.map(chatItem)

  return {
    key = "chatContent"
    size = [flex(), flex()]
    clipChildren = true
    children = children
    valign = ALIGN_BOTTOM
    gap = itemGap
    flow = FLOW_VERTICAL
    watch = [chatState.lines, localPlayerTeam]
//    behavior = Behaviors.SmoothScrollStack
//    speed = fsh(8)
  }
}


let function inputBox() {
  let textInput = {
    rendObj = ROBJ_SOLID
    color = CONTROL_BG_COLOR
    vplace = ALIGN_TOP
    size = [flex(), SIZE_TO_CONTENT]

    children = [
      function() {
        return {
          rendObj = ROBJ_TEXT
          size = [flex(), fontH(120)]
          margin = fsh(0.5)
          text = chatState.outMessage.value
          watch = chatState.outMessage
          behavior = Behaviors.TextInput
          function onChange(text) {
            chatState.outMessage(text)
          }
          function onAttach(elem) {
            capture_kb_focus(elem)
          }
          function onReturn() {
            if (chatState.outMessage.value.len()>0) {
              chatState.sendMessage({mode = chatState.sendMode.value,
                                      text = chatState.outMessage.value})
            }
            chatState.outMessage("")
            showChatInput(false)
          }
          hotkeys = [
            [$"Esc | {JB.B}", function() {
              chatState.outMessage("")
              showChatInput(false)
            }, "Close chat"]
          ]
        }.__update(sub_txt)
      }
    ]
  }

  let function sendModeText() {
    let mode = chatState.sendMode.value
    if (mode == "all")
      return loc("chat/all")
    if (mode == "team")
      return loc("chat/team")
    return "???"
  }

  let modesHelp = {
    vplace = ALIGN_BOTTOM
    size = [flex(), fsh(3)]
    children = [
      {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        text = loc("chat/help/short")
        color = Color(180, 180, 180, 180)
      }.__update(sub_txt)
      @() {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        watch = chatState.sendMode
        text = sendModeText()
      }.__update(body_txt)
    ]
  }

  let function switchSendModes() {
    let newMode = chatState.sendMode.value == "all" ? "team" : "all"
    if (switchSendModesAllowed)
      chatState.sendMode(newMode)
  }

  return {
    size = [flex(), inputBoxHeight]
    flow = FLOW_VERTICAL

    hotkeys = switchSendModesAllowed ? [ ["^Tab", switchSendModes] ] : null

    children = [
      textInput
      switchSendModesAllowed ? modesHelp : null
    ]
  }
}


let hasInteractiveChat = keepref(Computed(@() showChatInput.value))


hasInteractiveChat.subscribe(@(new_val) setInteractiveElement("chat", new_val))

msgbox.hasMsgBoxes.subscribe(function(shown_any) {
  // close chat to release keyboard capture when message box appears
  if (shown_any) {
    chatState.outMessage("")
    showChatInput(false)
  }
})


let inputBoxDummy = {size=[flex(), inputBoxHeight]}

let function chatRoot() {
  local children = null
  if (showChatInput.value) {
    children = [chatLog,inputBox]
  } else {
    children = [chatContent,inputBoxDummy]
  }

  return {
    key = "chat"
    flow = FLOW_VERTICAL
    size = [flex(), fsh(24)]

    watch = showChatInput

    children
  }
}

chatState.totalLines.subscribe(@(_) sound_play_one_shot("ui/new_log_message"))

return {
  chatRoot
  showChatInput
}
