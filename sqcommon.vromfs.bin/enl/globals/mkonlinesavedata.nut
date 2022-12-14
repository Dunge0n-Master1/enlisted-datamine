from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let { ndbWrite, ndbRead, ndbExists } = require("nestdb")

let mkSaveDataKey = @(saveId) $"onlineSaveData/{saveId.replace("/", "-")}"

let onlineSaveDataCache = persist("onlineSaveDataCache", @() {})

let function getOrMkSaveData(saveId, defValueFunc = @() null){
  if (saveId in onlineSaveDataCache)
    return onlineSaveDataCache[saveId]
  let key = mkSaveDataKey(saveId)
  let val = ndbExists(key) ? ndbRead(key) : defValueFunc()
  if (!ndbExists(key)) {
//    log("mkOnlineSaveData: no key found", key)
    ndbWrite(key, val)
  }
//  else
//    log("mkOnlineSaveData: key found", key, ndbRead(key))

  let watch = Watched(val)
  onlineSaveDataCache[saveId] <- watch
  watch.subscribe(function(v) {
//    log("mkOnlineSaveData: ndbWrite", key, v)
    ndbWrite(key, v)
  })
  return watch
}

let function mkOnlineSaveData(saveId, defValueFunc = @() null, validateFunc = @(v) v) {
  let watch = getOrMkSaveData(saveId, defValueFunc)
//  log("mkOnlineSaveData: init", saveId, watch.value)
  let update = function(value) {
    let v = validateFunc(value ?? defValueFunc())
//    dlog("mkOnlineSaveData: update", saveId, v)
    watch(v)
  }
  watch.whiteListMutatorClosure(update)
  eventbus.subscribe($"onlineData.changed.{saveId}", function(msg) {
//    dlog($"mkOnlineSaveData: onlineData.changed.{saveId}", msg.value)
    defer(@() update(msg.value))
  })

  return {
    watch
    setValue = function(value) {
//      log("mkOnlineSaveData: setValue", saveId, value)
      update(value)
      eventbus.send("onlineData.setValue", {saveId, value})
    }
  }
}

return {
  mkOnlineSaveData
  getOrMkSaveData
}