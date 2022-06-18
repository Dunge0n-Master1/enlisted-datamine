from "%enlSqGlob/ui_library.nut" import *

let {removeAllMsgboxes, getCurMsgbox, msgboxGeneration} = require("%ui/components/msgbox.nut")

gui_scene.setShutdownHandler(function sceneShutdownHandler() {
  removeAllMsgboxes()
})

let msgboxes = @() {
  size = flex()
  children = getCurMsgbox()
  watch = msgboxGeneration
}


return {msgboxes}