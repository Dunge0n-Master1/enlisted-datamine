from "%enlSqGlob/ui_library.nut" import *

let auth = require("auth")
let defLoginCb = require("%enlist/login/login_cb.nut")
let {startLogin} = require("%enlist/login/login_chain.nut")
let {linkSteamAccount} = require("%enlSqGlob/login_state.nut")
let msgbox = require("%enlist/components/msgbox.nut")


let isNewSteamAccount = mkWatched(persist, "isNewSteamAccount", false) //account which not linked

let function createSteamAccount() {
  linkSteamAccount(false)
  startLogin({ onlyKnown = false })
}

let steamNewAccountMsg = @() msgbox.show({
  text = loc("msg/steam/loginByGaijinNet")
  buttons = [
    { text = loc("LoginViaGaijinNet"), isCurrent = true, action = @() linkSteamAccount(true) }
    { text = loc("CreateSteamAccount"), action = createSteamAccount }
  ]
})

let function onSuccess(state) {
  state.userInfo.isNewSteamAccount <- isNewSteamAccount.value
  defLoginCb.onSuccess(state)
  isNewSteamAccount(false)
}

let function onInterrupt(state) {
  if (state?.status == auth.YU2_NOT_FOUND) {
    isNewSteamAccount(true)
    steamNewAccountMsg()
    return
  }

  defLoginCb.onInterrupt(state)
}

return {
  onSuccess = onSuccess
  onInterrupt = onInterrupt
}
