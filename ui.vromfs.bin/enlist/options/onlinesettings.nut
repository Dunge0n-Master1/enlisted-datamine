from "%enlSqGlob/ui_library.nut" import *

let shutdownHandler = require("%enlist/state/shutdownHandler.nut")
let eventbus = require("eventbus")
let userInfo = require("%enlSqGlob/userInfo.nut")
let online_storage = require("onlineStorage")
let { throttle } = require("%sqstd/timers.nut")
let platform = require("%dngscripts/platform.nut")
let logOS = require("%enlSqGlob/library_logs.nut").with_prefix("[ONLINE_SETTINGS] ")

let onlineSettingUpdated = mkWatched(persist, "onlineSettingUpdated", false)
let onlineSettingsInited = mkWatched(persist, "onlineSettingsInited", false)
let settings = mkWatched(persist, "onlineSettings", online_storage.get_table_from_online_storage("GBT_GENERAL_SETTINGS"))

const SEND_PENDING_TIMEOUT_SEC = 600 //10 minutes should be ok

let function onUpdateSettings(_userId) {
  let fromOnline = online_storage.get_table_from_online_storage("GBT_GENERAL_SETTINGS")
  settings.update(fromOnline)
  onlineSettingUpdated(true)
  onlineSettingsInited(true)
}

if (userInfo.value?.chardToken!=null && userInfo.value?.userId!=null && !onlineSettingsInited.value){ //hard reload support
  onUpdateSettings(userInfo.value?.userId)
}

local isSendToSrvTimerStarted = false

let function sendToServer() {
  if (!isSendToSrvTimerStarted)
    return //when timer not started, than settings already sent

  logOS("Send to server")
  gui_scene.clearTimer(callee())
  isSendToSrvTimerStarted = false
  online_storage.send_to_server()
}

let function startSendToSrvTimer() {
  if (isSendToSrvTimerStarted) {
    logOS("Timer to send is already on")
    return
  }

  isSendToSrvTimerStarted = true
  logOS("Start timer to send")
  gui_scene.setTimeout(SEND_PENDING_TIMEOUT_SEC, sendToServer)
}

userInfo.subscribe(function (new_val) {
  if (new_val != null)
    return
  sendToServer()
  onlineSettingUpdated(false)
})

let function save() {
  logOS("Save settings")
  online_storage.save_table_to_online_storage(settings.value, "GBT_GENERAL_SETTINGS")
}

let lazySave = throttle(save, platform.is_nswitch ? 60 : 10)

settings.subscribe(function(_new_val) {
  logOS("Queue setting to save")
  lazySave()
  startSendToSrvTimer()
})

let function loadFromCloud(userId, cb) {
  online_storage.load_from_cloud(userId, cb)
}

eventbus.subscribe("onlineSettings.sendToServer", @(_) sendToServer())

shutdownHandler.add(function() {
  logOS("Save and send online settings on shutdown")
  save()
  online_storage.send_to_server()
})

return {
  onUpdateSettings
  onlineSettingUpdated
  settings
  loadFromCloud
  startSendToSrvTimer
  sendToServer
}
