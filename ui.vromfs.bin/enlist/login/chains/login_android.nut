from "%enlSqGlob/ui_library.nut" import *

let login_cb = require("%enlist/login/login_cb.nut")
let auth  = require("auth")
let ah = require("%enlist/login/stages/auth_helpers.nut")
let eventbus = require("eventbus")

let googlePlayAccount = require("android.account.googleplay")

let function signInCallback(playerId, authCode, err, state, cb) {
  if (err == "") {
    state.authCode <- authCode
    state.playerId <- playerId
    cb({})
  }
  else
    cb({error=err})
}

let function start_googleplay_signin(state,cb) {
  eventbus.subscribe_onehit("android.account.googleplay.onSignInCallback", @(val) signInCallback(val.player_id,val.server_auth,val.error,state,cb))
  googlePlayAccount.startSignIn()
}


let function login_googleplay(state, cb) {
  let authCode = state.authCode
  let playerId = state.playerId
  eventbus.subscribe_onehit("login_googleplay", ah.status_cb(cb))
  auth.login_googleplay({authCode=authCode, playerId=playerId}, "login_googleplay")
}

return {
  stages = [
    { id = "start_googleplay_signin", action = start_googleplay_signin, actionOnReload = function(_state, _cb) {} },
    { id = "auth_googleplay", action = login_googleplay, actionOnReload = function(_state, _cb) {} },
    require("%enlist/login/stages/auth_result.nut"),
    require("%enlist/login/stages/char.nut"),
    require("%enlist/login/stages/online_settings.nut"),
    require("%enlist/login/stages/eula.nut"),
    require("%enlist/login/stages/matching.nut")
  ]
  onSuccess = login_cb.onSuccess
  onInterrupt = login_cb.onInterrupt
}
