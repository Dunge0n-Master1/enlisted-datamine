from "%enlSqGlob/ui_library.nut" import *

let saveload = require("%enlist/soldiers/model/saveload.nut")
let shutdownHandler = require("%enlist/state/shutdownHandler.nut")
let get_time_msec = require("dagor.time").get_time_msec

let canSaveDefault = Watched(true)

let function mkRequestSave(fileName, getSaveData, saveDelayMsec = 10000,
  canSave = canSaveDefault, needSave = Watched(false), saveRequested = Watched(-1)
) {
  let function save() {
    let data = getSaveData()
    saveload.save(fileName, data)
    needSave(false)
  }

  let function trySave() {
    if (canSave.value && needSave.value)
      save()
  }

  canSave.subscribe(@(_) trySave())
  shutdownHandler.add(@() needSave.value && save())

  let function requestSave() {
    needSave(true)
    if (saveRequested.value < get_time_msec()) {
      saveRequested(get_time_msec() + saveDelayMsec)
      gui_scene.setTimeout(0.001 * saveDelayMsec, trySave)
    }
  }
  return requestSave
}

return {
  load = saveload.load
  mkRequestSave = kwarg(mkRequestSave)
  canSave = canSaveDefault
}
