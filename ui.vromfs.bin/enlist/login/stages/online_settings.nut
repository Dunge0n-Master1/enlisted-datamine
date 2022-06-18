from "%enlSqGlob/ui_library.nut" import *

let onlineSettings = require("%enlist/options/onlineSettings.nut")

return {
  id = "online_settings"
  function action(state, cb) {
    onlineSettings.loadFromCloud(state.stageResult.auth_result.userId,
      function(result) {
        log($"load_personal_settings callback. res: {result}")
        onlineSettings.onUpdateSettings(state.stageResult.auth_result.userId)
        cb(result)
      })
  }
}
