from "%enlSqGlob/ui_library.nut" import *

let loginCb = require("%enlist/login/login_cb.nut")
let auth = require("auth")
let user = require("%xboxLib/impl/user.nut")
let privileges = require("%xboxLib/impl/privileges.nut")
let eventbus = require("eventbus")


// chain code
let function init_user(state, cb) {
  let login_function =
    (state.params?.xuid != null)
    ? user.init_default_user
    : user.init_user_with_ui

  login_function(function(xuid) {
    if (xuid > 0)
      cb({ xuid = xuid })
    else
      cb({ stop = true })
  })
}

let error_cb = @(cb, failure_loc_key, show_error, errorStr = null) @(success)
  success ? cb({}) : cb({error = failure_loc_key, needShowError = show_error, errorStr})

let function login_live(state, cb) {
  let failure_loc_key = "live_login_failed" // failed to login into live
  let xuid = state.stageResult.init_user.xuid
  log($"login live for user {xuid}")
  state.userInfo.xuid <- xuid
  // We don't need to pass xbox user hash here because it is added as xbl-authz-actor-10 header
  // that is just replaced with JWT disregarding of it's contents.
  // Later we don't need user hash, but xuid is useful. So stringified xuid will suffice.

  eventbus.subscribe_onehit("login_live", function(result) {
    let status = result?.status
    let status_text = auth.status_string(status)
    let full_error = $"{loc(failure_loc_key)} ({status_text})"
    error_cb(cb, failure_loc_key, true, full_error)(status == auth.YU2_OK)
  })
  auth.login_live(xuid.tostring(), "login_live")
}

let function check_priveleges(_state, cb) {
  let failure_loc_key = "permission_check_failure_mp" // Multiplayer is not permited
  let error_callback = error_cb(cb, failure_loc_key, false)
  privileges.retrieve_current_state(privileges.Privilege.Multiplayer, true, function(success, state, reason) {
    if (state == privileges.State.ResolutionRequired) {
      // if privilege was denied, check reason. If it requires resolution for Gold membership, allow login
      if (reason == privileges.DenyReason.PurchaseRequired)
        error_callback(true)
      else
        privileges.resolve_with_ui(privileges.Privilege.Multiplayer, function(success, state) {
          error_callback(success && (state == privileges.State.Allowed))
        })
    } else
      error_callback(success && (state == privileges.State.Allowed))
  })
}

let function onInterrupt(state) {
  user.shutdown_user()
  loginCb.onInterrupt(state)
}

return {
  stages = [
    { id = "init_user", action = init_user, actionOnReload = @(_state, _cb) null },
    { id = "auth_xbox", action = login_live, actionOnReload = @(_state, _cb) null },
    require("%enlist/login/stages/auth_result.nut"),
    { id = "permissions", action = check_priveleges, actionOnReload = @(_state, _cb) null },
    require("%enlist/login/stages/char.nut"),
    require("%enlist/login/stages/online_settings.nut"),
    require("%enlist/login/stages/eula.nut"),
    require("%enlist/login/stages/matching.nut")
  ]
  onSuccess = loginCb.onSuccess
  onInterrupt = onInterrupt
}
