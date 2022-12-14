from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let {logerr} = require("dagor.debug")
let { onlineSettingUpdated, settings } = require("onlineSettings.nut")
let { getOrMkSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")

let function onChange(_) {
//  log("mkOnlineSaveDataHub: onChange")
  if (!onlineSettingUpdated.value)
    return
  foreach(saveId, value in settings.value) {
    let nest = getOrMkSaveData(saveId).value
//    log($"mkOnlineSaveData: from online settings: {saveId} {value}, nest = {nest}")
    if (value == nest)
      continue
    eventbus.send($"onlineData.changed.{saveId}", { value })
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
  if (settings.value?[saveId] != value)
    settings.mutate(function(s) { s[saveId] <- value })
})

