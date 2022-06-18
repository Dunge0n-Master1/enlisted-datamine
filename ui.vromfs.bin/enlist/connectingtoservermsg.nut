from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let navState = require("navState.nut")
let {room, roomIsLobby, leaveRoom} = require("state/roomState.nut")

let textButton = require("%ui/components/textButton.nut")
let progressText = require("components/progressText.nut")

const TIME_TO_ALLOW_CANCEL = 7.0

let isNeedMsg = Computed(@()    room.value != null
                                && !roomIsLobby.value
                                && !(room.value?.gameStarted ?? false))
keepref(isNeedMsg)

let canCancelMsg = Watched(false)
isNeedMsg.subscribe(@(_) canCancelMsg(false))
let allowCancel = @() canCancelMsg(true)

isNeedMsg.subscribe(@(need) need ? gui_scene.setTimeout(TIME_TO_ALLOW_CANCEL, allowCancel)
  : gui_scene.clearTimer(allowCancel))




let cancelGameLaunchBtn = textButton(loc("mainmenu/btnCancel"),
  @() leaveRoom(function(...){}),
  {
    halign = ALIGN_CENTER
    textParams = h2_txt
    style = { BgNormal = Color(0,0,0,250)}
  }
)

let function gameLaunchingMsg() {
  let cancelGameLaunch = canCancelMsg.value ? cancelGameLaunchBtn : null
  return {
    watch = canCancelMsg
    size = [pw(100), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    pos = [0,sh(70)]
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    gap = hdpx(50)
    children = [
      progressText(loc("gameIsFound"))
      cancelGameLaunch
    ]
  }
}

let open = @() navState.addScene(gameLaunchingMsg)
if (isNeedMsg.value)
  open()

isNeedMsg.subscribe(@(need) need ? open()
  : navState.removeScene(gameLaunchingMsg))
