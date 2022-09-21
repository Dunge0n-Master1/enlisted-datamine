from "%enlSqGlob/ui_library.nut" import *

let {userInfo, userInfoUpdate} = require("%enlSqGlob/userInfoState.nut")
let {hideAllModalWindows} = require("%ui/components/modalWindows.nut")
let steam = require("steam")
let epic = require("epic")
let auth = require("auth")

let {get_setting_by_blk_path} = require("settings")

let isSteamRunning = mkWatched(persist, "isSteamRunning", steam.is_running())
let isEpicRunning = mkWatched(persist, "isEpicRunning", epic.is_running())
let isLoggedIn = keepref(Computed(@() userInfo.value != null))
let linkSteamAccount = mkWatched(persist, "linkSteamAccount", false)
let disableNetwork = get_setting_by_blk_path("debug")?.disableNetwork ?? false
let usePCLogin = get_setting_by_blk_path("debug")?.usePCLogin ?? false

let function logOut() {
  log("logout")
  hideAllModalWindows()
  userInfoUpdate(null)
}

console_register_command(logOut, "app.logout")

require("eventbus").subscribe(auth.token_renew_fail_event, function(_status) {
  log("logout due to auth token renew failure")
  logOut()
})

return {
  logOut
  isLoggedIn
  isSteamRunning
  isEpicRunning
  linkSteamAccount
  disableNetwork
  usePCLogin
}
