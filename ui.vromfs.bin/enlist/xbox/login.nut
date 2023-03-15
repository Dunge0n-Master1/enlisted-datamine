let { retrieve_auth_token } = require("%xboxLib/impl/user.nut")
let { get_xbox_login_url, login_live, status_string, YU2_WRONG_PARAMETER } = require("auth")
let { subscribe_onehit } = require("eventbus")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX LOGIN] ")


let function xbox_login_impl(token, signature, callback) {
  let eventName = "login_live"
  subscribe_onehit(eventName, function(result) {
    let status = result?.status
    let statusText = status_string(status)
    callback(status, statusText)
  })
  login_live(token, signature, eventName)
}


let function xbox_login(callback) {
  retrieve_auth_token(get_xbox_login_url(), "POST", function(success, token, signature) {
    logX($"get_auth_token succeeeded: {success}")
    if (!success) {
      callback(YU2_WRONG_PARAMETER, "Failed to get user token/signature")
      return
    }
    xbox_login_impl(token, signature, callback)
  })
}


return {
  xbox_login
}