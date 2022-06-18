from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let background = require("background.nut")
let progressText = require("%enlist/components/progressText.nut")
let regInfo = require("reginfo.nut")
let supportLink = require("supportLink.nut")

let {startLogin, currentStage} = require("%enlist/login/login_chain.nut")

let isFirstOpen = mkWatched(persist, "isFirstOpen", true)

let fontIconButton = require("%ui/components/fontIconButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let {exitGameMsgBox} = require("%enlist/mainMsgBoxes.nut")

let function onOpen() {
  if (!isFirstOpen.value)
    return
  isFirstOpen(false)
  startLogin({onlyKnown = true})
}

let function createLoginForm() {
  return [ regInfo ]
}

let centralContainer = @(children = null, watch = null, size = null) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = size
  watch = watch
  children = children
}

let function loginRoot() {
  onOpen()
  let size = [fsh(40), fsh(40)]
  let watch = [currentStage]

  if (currentStage.value)
    return centralContainer(
      progressText(loc("loggingInProcessEpic")), watch, size)

  return centralContainer(createLoginForm(), watch, size)
}

let headerHeight = calc_comp_size({size=SIZE_TO_CONTENT children={margin = [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(h2_txt)})[1]*0.75

return {
 size = flex()
 children = [
  background
  loginRoot
  supportLink
  {
      size = [headerHeight, headerHeight]
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.value[1]
      children = fontIconButton("power-off", { onClick = exitGameMsgBox })
    }
 ]
}

