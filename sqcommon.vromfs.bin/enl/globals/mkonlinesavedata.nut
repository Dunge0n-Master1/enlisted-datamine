from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")

let function mkOnlineSaveData(saveId, defValueFunc = @() null, validateFunc = @(v) v) {
  let watch = Watched(defValueFunc())
  let update = @(value) watch(validateFunc(value ?? defValueFunc()))
  let initialize = @(_ = null) eventbus.send("onlineData.init", { saveId })
  watch.whiteListMutatorClosure(update)
  eventbus.subscribe($"onlineData.changed.{saveId}", @(msg) update(msg.value))
  eventbus.subscribe("onlineData.hubReady", initialize)
  initialize()

  return {
    watch
    setValue = function(value) {
      update(value)
      eventbus.send("onlineData.setValue", {saveId, value})
    }
  }
}

return mkOnlineSaveData