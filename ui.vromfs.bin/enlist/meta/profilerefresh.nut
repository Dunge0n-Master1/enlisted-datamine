from "%enlSqGlob/ui_library.nut" import *

let { gfrnd } = require("dagor.random")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let matchingNotifications = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { update_profile, get_all_configs } = require("clientApi.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let logPR = require("%enlSqGlob/library_logs.nut").with_prefix("[profileRefresh] ")

const MAX_CONFIGS_UPDATE_DELAY = 120 //to prevent all users update configs at once.
  //but after the battle user will update configs if needed with profile even before timer.

let isProfileChanged = mkWatched(persist, "isProfileChanged", false)
let isConfigsChanged = mkWatched(persist, "isConfigsChanged", false)

let function checkUpdateProfile() {
  if (isInBattleState.value) {
    logPR("Delay update profile because in the battle")
    isProfileChanged(true)
    return
  }

  logPR($"Update profile: isProfileChanged = {isProfileChanged.value}, isConfigsChanged = {isConfigsChanged.value}")
  if (isConfigsChanged.value)
    get_all_configs()
  update_profile()
  isProfileChanged(false)
  isConfigsChanged(false)
}

isInBattleState.subscribe(function(v) {
  if (!v)
    logPR($"Leave battle: isProfileChanged = {isProfileChanged.value}")
  if (isProfileChanged.value)
    checkUpdateProfile()
})

let function updateConfigsTimer() {
  if (isConfigsChanged.value)
    gui_scene.setTimeout(gfrnd() * MAX_CONFIGS_UPDATE_DELAY, checkUpdateProfile)
  else
    gui_scene.clearTimer(checkUpdateProfile)
}
updateConfigsTimer()
isConfigsChanged.subscribe(@(_) updateConfigsTimer())

userInfo.subscribe(function(u) {
  if (u != null)
    return
  isProfileChanged(false)
  isConfigsChanged(false)
})

matchingNotifications.subscribe("profile",
  @(ev) ev?.func == "updateConfig" ? isConfigsChanged(true) : checkUpdateProfile())
