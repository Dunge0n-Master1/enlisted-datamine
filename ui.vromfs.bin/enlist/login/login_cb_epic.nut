from "%enlSqGlob/ui_library.nut" import *

let auth = require("auth")
let defLoginCb = require("%enlist/login/login_cb.nut")
let loginChain = require("%enlist/login/login_chain.nut")
let msgbox = require("%enlist/components/msgbox.nut")

let function createEpicAccount() {
  loginChain.startLogin({ onlyKnown = false })
}

let epicNewAccountMsg = @() msgbox.show({
  text = loc("msg/epic/loginByGaijinNet")
  buttons = [
    { text = loc("CreateEpicAccount"), action = createEpicAccount }
  ]
})

let function onSuccess(state) {
  defLoginCb.onSuccess(state)
}

let function onInterrupt(state) {
  if (state?.status == auth.YU2_NOT_FOUND) {
    epicNewAccountMsg()
    return
  }

  defLoginCb.onInterrupt(state)
}

return {
  onSuccess = onSuccess
  onInterrupt = onInterrupt
}
