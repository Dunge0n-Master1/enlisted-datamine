from "%enlSqGlob/ui_library.nut" import *

let anoPlayerCardUi = require("anoPlayerCardUi.nut")
let { isAnoProfileOpened } = require("anoProfileState.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { mkFooterWithButtons, PROFILE_WIDTH } = require("profilePkg.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { blurBgColor, bigOffset } = require("%enlSqGlob/ui/viewConst.nut")
let JB = require("%ui/control/gui_buttons.nut")

let anoProfileWindow = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = safeAreaBorders
  size = flex()
  padding = safeAreaBorders.value
  halign = ALIGN_CENTER
  color = blurBgColor
  children = {
    size = [PROFILE_WIDTH, flex()]
    flow = FLOW_VERTICAL
    padding = [bigOffset, 0]
    children = [
      anoPlayerCardUi()
      mkFooterWithButtons([
        Bordered(loc("BackBtn"), @() isAnoProfileOpened(false),
          { hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]})
      ])
    ]
  }
}

let function open() {
  sceneWithCameraAdd(anoProfileWindow, "events")
}

let function close() {
  sceneWithCameraRemove(anoProfileWindow)
}

if (isAnoProfileOpened.value)
  open()

isAnoProfileOpened.subscribe(@ (v) v ? open() : close())
