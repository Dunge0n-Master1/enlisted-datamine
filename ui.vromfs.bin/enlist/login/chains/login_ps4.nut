from "%enlSqGlob/ui_library.nut" import *

let loginCb = require("%enlist/login/login_cb.nut")
let ah = require("%enlist/login/stages/auth_helpers.nut")
let auth = require("auth")
let ps4 = require("ps4")
let psnUser = require("sony.user")
let {sendPsPlusStatusToUserstatServer = null} = require("%enlSqGlob/userstats/userstat.nut")
let { voiceChatEnabledUpdate } = require("%enlSqGlob/voiceChatGlobalState.nut")
let eventbus = require("eventbus")

let function login_psn(state, cb) {
  eventbus.subscribe_onehit("login_psn", ah.status_cb(cb))
  auth.login_psn(state.stageResult.ps4_auth_data, "login_psn")
}

let function ps4_auth_data_cb(cb) {
  return function(result) {
    if (result.error == true)
      result.error = "get_auth_data failed"
    else
      delete result.error
    cb(result)
  }
}

let function update_premium_permissions(_state, cb) {
  psnUser.requestPremiumStatusUpdate(@(_ignored) cb({}))
}

let function check_age_restrictions(cb) {
  return function(succeeded, message_needed) {
    if (succeeded) {
      cb({})
    } else {
      cb({ error = "age_restriction_check_failed", needShowError = message_needed })
    }
  }
}

let function check_parental_control(cb) {
  // true -> restricted
  return function(chat, _content, _ugc) {
    if (chat) {
      log("VoiceChat disabled due to parental control restrictions")
      voiceChatEnabledUpdate(false)
    }
    cb({})
  }
}

let function send_ps_plus_status(state) {
  if (sendPsPlusStatusToUserstatServer==null)
    return
  let token = state.stageResult.auth_result.token
  let havePsPlus = auth.have_ps_plus_subscription()
  log($"[PLUS] user has active subscription: {havePsPlus}")
  sendPsPlusStatusToUserstatServer(havePsPlus, token)
}

let function onSuccess(state) {
  loginCb.onSuccess(state)
  send_ps_plus_status(state)
}

return {
  stages = [
    { id = "check_age", action = @(_state, cb) ps4.check_age_restrictions(check_age_restrictions(cb)), actionOnReload = @(_state, _cb) null },
    { id = "parental_control", action = @(_state, cb) ps4.check_parental_control(check_parental_control(cb)), actionOnReload = @(_state, _cb) null },
    { id = "ps4_auth_data", action = @(_state, cb) ps4.get_auth_data_async(ps4_auth_data_cb(cb)), actionOnReload = @(_state, _cb) null },
    { id = "auth_psn", action = login_psn, actionOnReload = @(_state, _cb) null },
    { id = "check_plus", action = update_premium_permissions, actionOnReload = @(_state, _cb) null },
    require("%enlist/login/stages/auth_result.nut"),
    require("%enlist/login/stages/char.nut"),
    require("%enlist/login/stages/online_settings.nut"),
    require("%enlist/login/stages/eula.nut"),
    require("%enlist/login/stages/matching.nut"),
  ]
  onSuccess = onSuccess
  onInterrupt = loginCb.onInterrupt
}
