from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { get_userlogs } = require("%enlist/meta/clientApi.nut")
let { BattleResult } = require("%enlSqGlob/battleParams.nut")


enum UserLogType {
  PURCH_ITEM = "PURCH_ITEM"
  PURCH_SOLDIER = "PURCH_SOLDIER"
  PURCH_SQUAD = "PURCH_SQUAD"
  PURCH_WALLPOSTER = "PURCH_WALLPOSTER"
  PURCH_BONUS = "PURCH_BONUS"
  PURCH_PREMDAYS = "PURCH_PREMDAYS"

  BATTLE_ARMY_EXP = "BATTLE_ARMY_EXP"
  BATTLE_ACTIVITY = "BATTLE_ACTIVITY"
}


let userLogsTime = Watched(0)
let userLogsRaw = Watched({})
let userLogRowsRaw = Watched({})
let isUserLogsRequesting = Watched(false)

let userLogsDebug = Watched(null)
let userLogRowsDebug = Watched(null)

let userLogs = Computed(@() userLogsDebug.value ?? userLogsRaw.value)
let userLogRows = Computed(@() userLogRowsDebug.value ?? userLogRowsRaw.value)

let purchaseUserLogs = Computed(function() {
  let res = userLogs.value.values()
    .filter(@(ulog) (ulog?.shopItemId ?? "") != "")
    .apply(function(uLog) {
      uLog.rows <- userLogRows.value?[uLog.guid]
      return uLog
    })
    .sort(@(a, b) b.logTime <=> a.logTime)
  return res
})

let battlesUserLogs = Computed(function() {
  let res = userLogs.value.values()
    .filter(@(ulog) (ulog?.missionId ?? "") != "")
    .apply(function(uLog) {
      uLog.rows <- userLogRows.value?[uLog.guid]
      return uLog
    })
    .sort(@(a, b) b.logTime <=> a.logTime)
  return res
})

let function updateUserLogs(newValue) {
  isUserLogsRequesting(false)
  let newUserLogRows = {}
  let userLogsVal = newValue?.userLogs
  if (userLogsVal != null)
    userLogsRaw(userLogs.value.__merge(userLogsVal))
  foreach (userLogRow in newValue?.userLogRowsRaw ?? []) {
    let { guid } = userLogRow
    if (guid not in newUserLogRows)
      newUserLogRows[guid] <- []
    newUserLogRows[guid].append(userLogRow)
  }
  if (newUserLogRows.len() > 0)
    userLogRowsRaw.mutate(@(params) params.__update(newUserLogRows))
}

let function userLogsRequest() {
  if (isUserLogsRequesting.value)
    return

  isUserLogsRequesting(true)
  get_userlogs(userLogsTime.value, updateUserLogs)
  userLogsTime(serverTime.value)
}

const BATTLE_ARMY_EXP = "BATTLE_ARMY_EXP"
const BATTLE_ACTIVITY = "BATTLE_ACTIVITY"
let debugResult = [BattleResult.DESERTION, BattleResult.WIN, BattleResult.DEFEAT]

console_register_command(function(num) {
  if (num <= 0) {
    userLogsDebug(null)
    userLogRowsDebug(null)
    console_print("User log debug is turned OFF")
    return
  }
  let logs = {}
  let rows = {}
  for (local i = 0; i < num; ++i) {
    let guid = $"log{i}"
    let missionId = $"test_map{i}"
    let activity = i.tofloat() / num
    logs[guid] <- { guid, logTime = i, missionId, value = debugResult[i % debugResult.len()] }
    rows[guid] <- [
      { logType = BATTLE_ARMY_EXP, guid, armyId = "moscow_allies", count = (i + 5) * 100 },
      { logType = BATTLE_ACTIVITY, guid, count = (activity * 100).tointeger() }]
  }
  userLogsDebug(logs)
  userLogRowsDebug(rows)
  console_print("User log debug is turned ON")
}, "meta.genDebugUserLogs")

console_register_command(userLogsRequest, "meta.getUserLogs")

return {
  UserLogType
  userLogsRequest
  purchaseUserLogs
  battlesUserLogs
  isUserLogsRequesting
}
