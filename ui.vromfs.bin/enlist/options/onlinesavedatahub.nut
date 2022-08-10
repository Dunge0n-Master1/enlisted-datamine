from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let {logerr} = require("dagor.debug")
let { onlineSettingUpdated, settings } = require("onlineSettings.nut")

let lastValues = {}

let sendValue = @(saveId) eventbus.send($"onlineData.changed.{saveId}", { value = lastValues[saveId] })

let getCurValue = @(saveId) onlineSettingUpdated.value ? settings.value?[saveId] : null

eventbus.subscribe("onlineData.init", function(msg) {
  let {saveId} = msg
  lastValues[saveId] <- getCurValue(saveId)
  sendValue(saveId)
})

let function onChange(_) {
  foreach (saveId, value in lastValues) {
    let newValue = getCurValue(saveId)
    if (newValue == value)
      continue
    lastValues[saveId] = newValue
    sendValue(saveId)
  }
}
onlineSettingUpdated.subscribe(onChange)
settings.subscribe(onChange)

eventbus.subscribe("onlineData.setValue", function(msg) {
  let { saveId, value } = msg
  if (!onlineSettingUpdated.value) {
    logerr($"onlineSaveDataHub: try to set value to {saveId} while online options not inited")
    return
  }
  if (lastValues?[saveId] != value)
    settings.mutate(function(s) { s[saveId] <- value })
})

eventbus.send("onlineData.hubReady", null)
