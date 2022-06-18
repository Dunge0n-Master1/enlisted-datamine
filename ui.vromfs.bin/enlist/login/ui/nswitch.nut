from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let background = require("background.nut")
let textButton = require("%ui/components/textButton.nut")
let {bottomEulaUrl} = require("eulaUrlView.nut")
let progressText = require("%enlist/components/progressText.nut")
let {safeAreaBorders} = require("%enlist/options/safeAreaState.nut")

let {startLogin, currentStage} = require("%enlist/login/login_chain.nut")
let loginDarkStripe = require("loginDarkStripe.nut")

let { loginBlockOverride, infoBlock } = require("loginUiParams.nut")
let isFirstOpen = mkWatched(persist, "isFirstOpen", true)
let nswitchAccount = require("nswitch.account")


let function loginBtnAction() {
  startLogin({})
}


let loginBtn = textButton(loc("Login"), loginBtnAction,
  { size = [flex(), hdpx(70)], halign = ALIGN_CENTER, margin = 0
    hotkeys = [["^J:Y", { description = { skip = true }}]]
  }.__update(h2_txt)
)

let function loginRoot() {
  let doAutoLogin = isFirstOpen.value && (nswitchAccount.getNsoStatus() == nswitchAccount.OK);

  let children = doAutoLogin
    ? progressText(loc("loggingInProcess"))
    : currentStage.value ? progressText(loc("loggingInProcess")) : loginBtn

  return {
    watch = [ currentStage, loginBlockOverride ]
    children = children
    onAttach = function() {
      if (doAutoLogin) {
        isFirstOpen(false)
        loginBtnAction()
      }
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    pos = [-sw(15), 0]
  }.__update(loginBlockOverride.value)
}

return @() {
  watch = [safeAreaBorders, infoBlock]
  size = flex()
  padding = safeAreaBorders.value
  children = [
    background
    loginDarkStripe
    infoBlock.value
    loginRoot
    bottomEulaUrl
  ]
}

