from "%enlSqGlob/ui_library.nut" import *

let { startLogin } = require("%enlist/matchingClient.nut")
let eventbus = require("eventbus")

return {
  id = "matching"
  function action(processState, cb) {
    let stageResult = processState.stageResult
    let uinfo = {
      userId = stageResult.auth_result.userId
      name = stageResult.auth_result.name
      chardToken = stageResult.char.chard_token
    }
    eventbus.subscribe_onehit("matching.logged_in", @(...) cb({}))
    eventbus.subscribe_onehit("matching.login_failed", cb)
    startLogin(uinfo)
  }
  function actionOnReload(_state, cb) {
    eventbus.subscribe_onehit("matching.logged_in", @(...) cb({}))
    eventbus.subscribe_onehit("matching.login_failed", cb)
  }
}
