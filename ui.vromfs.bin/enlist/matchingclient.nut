from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let matching_api = require("matching.api")
let matching_errors = require("matching.errors")
let connectHolder = require("%enlist/connectHolderR.nut")
let loginState = require("%enlSqGlob/login_state.nut")
let appInfo =  require("%dngscripts/appInfo.nut")
let platform = require("%dngscripts/platform.nut")
let nswitchNetwork = platform.is_nswitch ? require("nswitch.network") : null
let eventbus = require("eventbus")

local matchingLoginActions = []
let debugDelay = mkWatched(persist, "debugDelay", 0)

loginState.isLoggedIn.subscribe(function(val) {
  if (!val)
    connectHolder.deactivate_matching_login()
})

let function netStateCall(func) {
  if (connectHolder.is_logged_in())
    func()
  else
    matchingLoginActions.append(func)
}

let mkDetailsDisconnect = platform.is_nswitch
         ? @() { text = loc("Details"), action = @() nswitchNetwork.handleRequestAndShowError() }
         : null


let function matchingCallImpl(cmd, cb = null, params = null) {
  let res = matching_api.call(cmd, params)
  if (cb == null)
    return
  if (res?.reqId != null)
    eventbus.subscribe_onehit($"{cmd}.{res.reqId}", cb)
  else
    cb(res)
}

let matchingCall = @(cmd, cb = null, params = null) debugDelay.value <= 0
  ? matchingCallImpl(cmd, cb, params)
  : gui_scene.setTimeout(debugDelay.value, @() matchingCallImpl(cmd, cb, params))

let function matchingNotify(cmd, params=null) {
  netStateCall(function() { matching_api.notify(cmd, params) })
}

eventbus.subscribe("matching.login_failed", function(_result) {
  matchingLoginActions = []
  loginState.logOut()
})

eventbus.subscribe("matching.logged_out", function(notify) {
  matchingLoginActions = []
  loginState.logOut()

  if (notify != null) {
    if (notify.reason == matching_errors.DisconnectReason.ConnectionClosed && notify.message.len() == 0) {
      let buttons = [{ text = loc("Ok"), isCurrent = true, action = @() null }]
      let detailsBtn = mkDetailsDisconnect?()
      if (detailsBtn != null)
        buttons.append(detailsBtn)
      msgbox.show({
        text = loc("error/CLIENT_ERROR_CONNECTION_CLOSED")
        buttons = buttons
      })
    }
    else {
      log($"Matching server disconnect by {notify.reason} with message {notify.message}")
      msgbox.show({
        text = loc("msgboxtext/matchingDisconnect",
          {error = loc("error/{0}".subst(notify.reason_str))})
      })
    }
  }
})

eventbus.subscribe("matching.logged_in", function(_reason) {
  let actions = matchingLoginActions
  matchingLoginActions = []
  foreach (act in actions)
    act()
})

let function startLogin(userInfo) {
  let loginInfo = {
    userId = userInfo.userId
    userName = userInfo.name
    token = userInfo.chardToken
    versionStr = appInfo.version.value
  }

  connectHolder.activate_matching_login(loginInfo)
}

console_register_command(@(delay) debugDelay(delay), "matching.delay_calls")

return {
  serverResponseError = connectHolder.server_response_error
  matchingCall
  matchingNotify
  startLogin
  netStateCall
}
