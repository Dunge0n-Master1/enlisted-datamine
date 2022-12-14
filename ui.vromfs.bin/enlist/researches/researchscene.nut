from "%enlSqGlob/ui_library.nut" import *

let researchesUi = require("researchesUi.nut")
let JB = require("%ui/control/gui_buttons.nut")

let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontXXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { isResearchesOpened } = require("%enlist/mainMenu/sectionsState.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let {
  topWndBgColor, bottomWndBgColor, colPart, columnGap, titleTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


let headerTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)


let profileWindow = @() {
  watch = safeAreaBorders
  size = flex()
  padding = safeAreaBorders.value
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(topWndBgColor, bottomWndBgColor)
  children = [
    researchesUi
    {
      flow = FLOW_HORIZONTAL
      gap = colPart(2)
      margin = [columnGap, 0]
      valign = ALIGN_CENTER
      children = [
        Bordered(loc("BackBtn"), @() isResearchesOpened(false), {
          hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") }]]
        })
        {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_CENTER
          text = utf8ToUpper(loc("menu/researches"))
        }.__update(headerTxtStyle)
      ]
    }
  ]
}

let function open() {
  sceneWithCameraAdd(profileWindow, "soldiers")
}

let function close() {
  sceneWithCameraRemove(profileWindow)
}

if (isResearchesOpened.value)
  open()

isResearchesOpened.subscribe(@ (v) v ? open() : close())

return function() {
  isResearchesOpened(true)
}
