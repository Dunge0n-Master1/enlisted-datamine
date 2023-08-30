from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let background = require("background.nut")
let textButton = require("%ui/components/textButton.nut")
let progressText = require("%enlist/components/progressText.nut")
let supportLink = require("supportLink.nut")
let {startLogin, currentStage} = require("%enlist/login/login_chain.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let {safeAreaBorders} = require("%enlist/options/safeAreaState.nut")
let {exitGameMsgBox} = require("%enlist/mainMsgBoxes.nut")

let loginBtn = textButton(loc("Login"),
                            @() startLogin({}),
                            fontSub)

let function loginRoot() {
  let size = [fsh(40), fsh(40)]
  let watch = [currentStage]

  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = size
    watch = watch
    function onAttach() {
      startLogin({})
    }
    children = currentStage.value ?
                progressText(loc("loggingInProcess")) :
                loginBtn
  }
}

let height = calc_comp_size({size=SIZE_TO_CONTENT children={margin = [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(fontHeading2)})[1]*0.75

return {
 size = flex()
 children = [
  background
  loginRoot
  supportLink
  {
      size = [height, height]
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.value[1]
      children = fontIconButton("power-off", { onClick = exitGameMsgBox })
    }
 ]
}

