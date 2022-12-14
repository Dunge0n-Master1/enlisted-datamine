from "%enlSqGlob/ui_library.nut" import *

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { matchingCall } = require("matchingClient.nut")
let matching_api = require("matching.api")
let connectHolder = require("%enlist/connectHolderR.nut")
let { isPlatformRelevant } = require("%dngscripts/platform.nut")
let { get_app_id } = require("app")
let eventbus = require("eventbus")
let {get_setting_by_blk_path} = require("settings")
let {nestWatched} = require("%dngscripts/globalState.nut")


let matchingGameName = get_setting_by_blk_path("matchingGameName")
log($"matchingGameName in settings.blk {matchingGameName}")

let matchingQueuesRaw = nestWatched("matchingQueuesRaw", [])

let function processQueues(val) {
  let curGame = matchingGameName
  local queues = val.filter(@(q) (q.game == curGame || curGame==null) && isPlatformRelevant(q?.allowedPlatforms ?? []))
  if (queues.len()==0)
    queues = val
  queues = queues.map(@(queue) {
    id = queue.queueId
    locId = queue?.locId
    uiOrder = queue?.extraParams.uiOrder ?? 1000
    uiGroup = queue?.extraParams.uiGroup ?? "z"
    extraParams = clone (queue?.extraParams ?? {})
    maxGroupSize = queue?.maxGroupSize ?? queue?.groupSize ?? 1
    minGroupSize = queue?.minGroupSize ?? 1
    allowFillGroup = queue?.allowFillGroup ?? true
  }.__update(queue))
  queues.sort(@(next, prev)
    next.uiOrder <=> prev.uiOrder
    || next.uiGroup <=> prev.uiGroup
    || next.maxGroupSize <=> prev.maxGroupSize
  )
  return queues
}

let matchingQueues = Computed(function(prev) {
  if (prev != FRP_INITIAL && isInBattleState.value)
    return prev
  else if (prev == FRP_INITIAL && isInBattleState.value)
    return {}
  return processQueues(matchingQueuesRaw.value)
})

let function fetch_matching_queues() {
  let fetchMatchingQueues = fetch_matching_queues
  matchingCall("enlmm.get_queues_list",
    function(response) {
      debugTableData(response)
      if (!connectHolder.is_logged_in())
        return
      if (response.error != 0) {
        gui_scene.resetTimeout(5, fetchMatchingQueues)
        return
      }
      matchingQueuesRaw.update(response?.queues ?? [])
    }, {appId = get_app_id()})
}

eventbus.subscribe("matching.logged_in", @(...) fetch_matching_queues())

let function checkEmptyQueues(){
  if (matchingQueues.value.len()!=0 || !connectHolder.is_logged_in())
    return
  fetch_matching_queues()
}

gui_scene.setInterval(15, checkEmptyQueues) //? TODO: make exponential backoff here

matching_api.listen_notify("enlmm.notify_games_list_changed")
eventbus.subscribe("enlmm.notify_games_list_changed", @(_notify) fetch_matching_queues())

return {
  matchingQueues
}
