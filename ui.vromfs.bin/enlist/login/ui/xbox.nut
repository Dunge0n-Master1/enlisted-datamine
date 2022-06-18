from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let background = require("background.nut")
let colors = require("%ui/style/colors.nut")
let textButton = require("%ui/components/textButton.nut")
let {bottomEulaUrl} = require("eulaUrlView.nut")
let progressText = require("%enlist/components/progressText.nut")
let loginDarkStripe = require("loginDarkStripe.nut")

let {startLogin, currentStage} = require("%enlist/login/login_chain.nut")
let { loginBlockOverride, infoBlock } = require("loginUiParams.nut")

let loginButtonRedrawCounter = Watched(0)

let function loginBtnAction() {
  loginButtonRedrawCounter(loginButtonRedrawCounter.value + 1)
  if (currentStage.value == null)
    startLogin({})
}

//The login button is covered with crutches as it hangs when the account selection menu is displayed
let function loginBtn() {
  return {
    size = [flex(), hdpx(70)]
    watch = loginButtonRedrawCounter
    children = textButton(loc("Login"), loginBtnAction,
      { size = [flex(), hdpx(70)], key = "loginBtn_{0}".subst(loginButtonRedrawCounter.value), halign = ALIGN_CENTER, margin = 0
        hotkeys = [["^J:Y", { description = { skip = true }}]]
      }.__update(h2_txt))
  }
}

let descriptionBlock = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = colors.BtnTextNormal
  text
}.__update(body_txt)

let loginFormChildren = [
  loginBtn
  {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      descriptionBlock(loc("login/needConstantInternetMessage"))
    ]
  }
]

let function loginRoot() {
  let children = currentStage.value
    ? progressText(loc("loggingInProcess"))
    : loginFormChildren

  return {
    watch = [ currentStage, loginBlockOverride ]
    flow = FLOW_VERTICAL
    pos = [-sw(15), 0]
    gap = hdpx(25)
    children = children
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
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
