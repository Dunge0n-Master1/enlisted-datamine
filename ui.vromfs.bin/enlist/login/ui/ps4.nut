from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let background = require("background.nut")
let textButton = require("%ui/components/textButton.nut")
let {bottomEulaUrl} = require("eulaUrlView.nut")
let progressText = require("%enlist/components/progressText.nut")
let {safeAreaBorders} = require("%enlist/options/safeAreaState.nut")

let {startLogin, currentStage} = require("%enlist/login/login_chain.nut")
let loginDarkStripe = require("loginDarkStripe.nut")

let { loginBlockOverride, infoBlock } = require("loginUiParams.nut")


let function loginBtnAction() {
  startLogin({})
}

let loginBtn = textButton(loc("Login"), loginBtnAction,
  { size = [flex(), hdpx(70)], halign = ALIGN_CENTER, margin = 0
    hotkeys = [["^J:Y", { description = { skip = true }}]]
  }.__update(fontHeading2)
)

let isFirstOpen = mkWatched(persist, "isFirstOpen", true)

let function loginRoot() {
  let children = isFirstOpen.value
    ? [progressText(loc("loggingInProcess"))]
    : currentStage.value ? [progressText(loc("loggingInProcess"))] : [ loginBtn ]
  return {
    watch = [ currentStage, safeAreaBorders, loginBlockOverride ]
    padding = safeAreaBorders.value
    onAttach = function() {
      if (isFirstOpen.value && currentStage.value == null) {
        isFirstOpen(false)
        loginBtnAction()
      }
    }
    pos = [-sw(15), 0]
    flow = FLOW_VERTICAL
    gap = hdpx(25)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }.__update(loginBlockOverride.value)
}

return @() {
  watch = infoBlock
  size = flex()
  children = [
    background
    loginDarkStripe
    infoBlock.value
    loginRoot
    bottomEulaUrl
  ]
}
