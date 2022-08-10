from "%enlSqGlob/ui_library.nut" import *
let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {MenuBgOverlay} = require("%ui/style/colors.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { actionInProgress } = require("%enlSqGlob/uistate.nut")
let spinner = require("%ui/components/spinner.nut")()

const WND_UID = "actionInProgress"

let close = @() removeModalWindow(WND_UID)

let function open() {
  addModalWindow({
    key = WND_UID
    zOrder = Layers?.Blocker ?? 0
//    rendObj = ROBJ_WORLD_BLUR_PANEL
//    fillColor = colors.ModalBgTint
    rendObj = ROBJ_SOLID
    color = MenuBgOverlay
    onClick = @() null
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      {
        size = [sw(50), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = loc("xbox/waitingMessage")
      }.__update(body_txt)
      spinner
    ]
  })
}

if (actionInProgress.value)
  open()

actionInProgress.subscribe(@(d) d ? open() : close())
