from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {MenuBgOverlay} = require("%ui/style/colors.nut")
let { controllerDisconnected } = require("%enlSqGlob/controllerDisconnected.nut")
let {removeModalWindow, addModalWindow} = require("%ui/components/modalWindows.nut")

const WND_UID = "disconnectedControllerMsg"

let close = @() removeModalWindow(WND_UID)

let function open() {
  addModalWindow({
    key = WND_UID
    zOrder = Layers?.Blocker ?? 100
//    rendObj = ROBJ_WORLD_BLUR_PANEL
    rendObj = ROBJ_SOLID
    onClick = @() null
    valign = ALIGN_CENTER
    color = MenuBgOverlay
    halign = ALIGN_CENTER
    children = {
      size = [sw(50), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc("xbox/controllerDisconnected")
    }.__update(body_txt)
  })
}

if (controllerDisconnected.value)
  open()
controllerDisconnected.subscribe(@(d) d ? open() : close())
