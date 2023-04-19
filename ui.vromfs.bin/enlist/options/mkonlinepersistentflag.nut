from "%enlSqGlob/ui_library.nut" import *

let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { onlineSettingUpdated } = require("onlineSettings.nut")
let { watch, setValue } = mkOnlineSaveData("onlinePersistentFlags", @() {})

let function mkOnlinePersistentWatched(id, flag) {
  let function save(val) {
    if (onlineSettingUpdated.value && val)
      setValue(watch.value.__merge({ [id] = true }))
  }
  save(flag.value)
  flag.subscribe(save)
  onlineSettingUpdated.subscribe(@(_) save(flag.value))
  return Computed(@() watch.value?[id] ?? flag.value ?? false)
}

let mkOnlinePersistentFlag = @(id) {
  flag = Computed(@() watch.value?[id] ?? false)
  activate = function() {
    if (onlineSettingUpdated.value)
      setValue(watch.value.__merge({ [id] = true }))
  }
}

console_register_command(@() setValue({}), "ui.resetPersistentFlags")
console_register_command(@()
  console_print("Persistent flags:", watch.value), "ui.printPersistentFlags")
console_register_command(function(id) {
  let val = !(watch.value?[id] ?? false)
  console_print($"Persistent flag {id} switched to {val}")
  setValue(watch.value.__merge({ [id] = val }))
}, "ui.togglePersistentFlag")

return {
  mkOnlinePersistentWatched
  mkOnlinePersistentFlag
}
