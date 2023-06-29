from "%enlSqGlob/ui_library.nut" import *

// R is for reactive

let matching_api = require("matching.api")
let matching_errors = require("matching.errors")
let logM = require("%enlSqGlob/library_logs.nut").with_prefix("[MATCHING] ")
let eventbus = require("eventbus")
let {nestWatched} = require("%dngscripts/globalState.nut")

let matchingConnectState = nestWatched("matchingConnectState", {
    connecting = false
    stopped = false
    isLoggedIn = false
    loginFailCount = 0
    reconnectAfterDisconnect = false
    disconnectReason = null
    lastLoginInfo = null
})

let getState = @() freeze(matchingConnectState.value)

let setState = function(key, value) {
  assert(key in matchingConnectState.value, @() $"unknown {key}")
  matchingConnectState.mutate(@(v) v[key] <- value)
}

let serverResponseError = mkWatched(persist, "serverResponseError", false)

const max_relogin_retry_count = 3

eventbus.subscribe("matching.logged_in",
  function(...) {
    setState("isLoggedIn", true)
    eventbus.send("matching.connectHolder.ready", null)
    if (getState().stopped == true) {
      logM("matching connection was stopped during connect process")
      matching_api.logout()
    }
  })

eventbus.subscribe("matching.logged_out",
  function(...) {
    setState("isLoggedIn", false)
  })

let function is_retriable_login_error(loginerror) {
  if (loginerror == matching_errors.LoginResult.NameResolveFailed ||
      loginerror == matching_errors.LoginResult.FailedToConnect ||
      loginerror == matching_errors.LoginResult.ServerBusy ||
      loginerror == matching_errors.LoginResult.PeersLimitReached)
    return true
  return false
}

let function performConnect(login_info) {
  logM($"matching.performConnect", login_info != null, getState().loginFailCount)
  serverResponseError(false)
  if (getState().connecting || login_info == null) {
    return
  }
  setState("stopped", false)
  setState("connecting", true)
  matching_api.dial(login_info)
}

eventbus.subscribe("matching.dial_finished", function(result) {
  setState("connecting", false)
  serverResponseError(result.status != 0)
  if (result.status == 0) {
    logM("matching login successfull")
    eventbus.send("matching.logged_in", null)
  }
  else {
    logM($"matching login failed: \"{result.status_str}\"")
    if (getState().loginFailCount < max_relogin_retry_count && !getState().stopped && is_retriable_login_error(result.status)) {
      setState("loginFailCount", getState().loginFailCount+1)
      gui_scene.setTimeout(3, @() performConnect(getState().lastLoginInfo))
    }
    else {
      if (getState().reconnectAfterDisconnect) {
        serverResponseError(false)
        eventbus.send("matching.logged_out", getState().disconnectReason)
      }
      else
        eventbus.send("matching.login_failed", {error = result.status_str})
    }
  }
})


let function deactivate_matching_login() {
  setState("stopped", true)
  if (!getState().connecting)
    matching_api.logout()
  setState("lastLoginInfo", null)
}

let function activate_matching_login(loginInfo) {
  logM($"matching login using name {loginInfo.userName} and user_id {loginInfo.userId}")
  setState("lastLoginInfo", loginInfo)
  setState("loginFailCount", 0)
  setState("reconnectAfterDisconnect", false)
  setState("disconnectReason", null)
  performConnect(loginInfo)
}

let function restore_connection(_login_info, disconnect_reason) {
  setState("loginFailCount", 0)
  setState("reconnectAfterDisconnect", true)
  setState("disconnectReason", disconnect_reason)
  performConnect(getState().lastLoginInfo)
}

eventbus.subscribe("matching.on_disconnect",
  function(disconnect_info) {
    logM("client had been disconnected from matching")
    logM(disconnect_info)

    if (getState().stopped) {
      logM("do logout")
      eventbus.send("matching.logged_out", null)
      return
    }

    local doLogout = false
    if (disconnect_info.message.len() > 0)
      doLogout = true
    else {
      switch (disconnect_info.reason) {
        case matching_errors.DisconnectReason.CalledByUser:
        case matching_errors.DisconnectReason.ForcedLogout:
        case matching_errors.DisconnectReason.SecondLogin:
          doLogout = true
          break
        //case matching_errors.DisconnectReason.ConnectionClosed:
        //case matching_errors.DisconnectReason.ForcedReconnect:
      }
    }

    if (doLogout) {
      eventbus.send("matching.logged_out", disconnect_info)
    }
    else {
      //try to reconnect only if already logged in
      if (getState().isLoggedIn && getState().lastLoginInfo) {
        gui_scene.setTimeout(3, @() restore_connection(getState().lastLoginInfo, disconnect_info))
      }
    }
  })

return {
  activate_matching_login = activate_matching_login
  deactivate_matching_login = deactivate_matching_login
  is_logged_in = @() getState().isLoggedIn
  server_response_error = serverResponseError
}
