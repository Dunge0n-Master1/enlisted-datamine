from "%enlSqGlob/ui_library.nut" import *

let { update_profile, get_all_configs } = require("%enlist/meta/clientApi.nut")
let { updateAllConfigs } = require("%enlist/meta/configs.nut")

let updateList = [
  { id = "update_profile", request = update_profile }
  { id = "get_all_configs", request = get_all_configs, onSuccess = updateAllConfigs }
]
let ALL = (1 << updateList.len()) - 1

let function startRequest(data, idx, shared) {
  let { id, request, onSuccess = @(_) null } = data
  request(function cb(res) {
    if (shared.isFailed)
      return //not actual answer
    shared.result[id] <- res
    if (res?.error != null) {
      shared.isFailed = true
      shared.result.error <- res.error
      shared.onAllFinishCb(shared.result)
      return
    }
    onSuccess(res)
    shared.current += 1 << idx
    if (shared.current == ALL)
      shared.onAllFinishCb(shared.result)
  }, shared.token)
}

return {
  id = "pServerProfileAndConfigs"
  function action(processState, cb) {
    let token = processState.stageResult.auth_result.token
    let shared = { current = 0, result = {}, onAllFinishCb = cb, isFailed = false, token = token }
    updateList.each(@(data, idx) startRequest(data, idx, shared))
  }
}