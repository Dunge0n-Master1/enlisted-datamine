from "%enlSqGlob/ui_library.nut" import *

let { frnd } = require("dagor.random")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let matchingNotifications = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { update_profile, get_all_configs } = require("clientApi.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")
let logPR = require("%enlSqGlob/library_logs.nut").with_prefix("[profileRefresh] ")

const MAX_CONFIGS_UPDATE_DELAY = 120 //to prevent all users update configs at once.
  //but after the battle user will update configs if needed with profile even before timer.

let isProfileChanged = nestWatched("isProfileChanged", false)
let isConfigsChanged = nestWatched("isConfigsChanged", false)

let function checkUpdateProfile() {
  if (isInBattleState.value) {
    logPR("Delay update profile because in the battle")
    return
  }

  logPR($"Update profile: isProfileChanged = {isProfileChanged.value}, isConfigsChanged = {isConfigsChanged.value}")
  if (isConfigsChanged.value) {
    get_all_configs()
    isConfigsChanged(false)
  }
  if (isProfileChanged.value) {
    update_profile()
    isProfileChanged(false)
  }
}

isInBattleState.subscribe(function(v) {
  if (v)
    isProfileChanged(true)
  else {
    logPR($"Check updates on leave battle")
    checkUpdateProfile()
  }
})

let function updateConfigsTimer() {
  if (isConfigsChanged.value)
    gui_scene.setTimeout(frnd() * MAX_CONFIGS_UPDATE_DELAY, checkUpdateProfile)
  else
    gui_scene.clearTimer(checkUpdateProfile)
}

isConfigsChanged.subscribe(@(_) updateConfigsTimer())

userInfo.subscribe(function(u) {
  if (u != null)
    return
  isProfileChanged(false)
  isConfigsChanged(false)
})

matchingNotifications.subscribe("profile", function(ev) {
  isProfileChanged(true)
  if (ev?.func == "updateConfig")
    isConfigsChanged(true)
  else
    checkUpdateProfile()
})
