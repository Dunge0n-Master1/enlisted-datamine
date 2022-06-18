from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { get_userlogs } = require("%enlist/meta/clientApi.nut")


let userLogsTime = mkWatched(persist, "userLogsTime", 0)
let userLogs = mkWatched(persist, "userLogs", {})
let userLogRows = mkWatched(persist, "userLogRows", {})
let isUserLogsRequesting = Watched(false)

let purchaseUserLogs = Computed(function() {
  let res = userLogs.value.values()
    .filter(@(log) log.shopItemId != "")
    .sort(@(a, b) b.logTime <=> a.logTime)
  return res
})

let battlesUserLogs = Computed(function() {
  let res = userLogs.value.values()
    .filter(@(log) log.missionId != "")
    .sort(@(a, b) b.logTime <=> a.logTime)
  return res
})

let function updateUserLogs(newValue) {
  isUserLogsRequesting(false)
  let newUserLogRows = {}
  let userLogsVal = newValue?.userLogs
  if (userLogsVal != null)
    userLogs(userLogs.value.__merge(userLogsVal))
  foreach (userLogRow in newValue?.userLogRows ?? []) {
    let { guid } = userLogRow
    if (guid not in newUserLogRows)
      newUserLogRows[guid] <- []
    newUserLogRows[guid].append(userLogRow)
  }
  if (newUserLogRows.len() > 0)
    userLogRows.mutate(@(params) params.__update(newUserLogRows))
}

let function requestUserLogs() {
  if (isUserLogsRequesting.value)
    return

  isUserLogsRequesting(true)
  get_userlogs(userLogsTime.value, updateUserLogs)
  userLogsTime(serverTime.value)
}

console_register_command(requestUserLogs, "meta.getUserLogs")

return {
  userLogRows
  requestUserLogs
  purchaseUserLogs
  battlesUserLogs
  isUserLogsRequesting
}
