from "%enlSqGlob/ui_library.nut" import *

let { strip } = require("string")
let { userstatUnlocks, userstatDescList, userstatStats } = require("%enlSqGlob/userstats/userstat.nut")

let isDebugPersonal = mkWatched(persist, "isDebugPersonal", false)
const DAILY_TASK_KEY = "daily"

let emptyProgress = {
  stage = 0
  lastRewardedStage = 0
  current = 0
  required = 1
  isCompleted = false
  hasReward = false
  isFinished = false //isCompleted && !hasReward
}

let unlockTablesBase = keepref(Computed(function() {
  let stats = userstatStats.value
  let res = {}
  foreach (name, _value in stats?.stats ?? {})
    res[name] <- true
  foreach (name, _value in stats?.inactiveTables ?? {})
    res[name] <- false
  return res
}))

let unlockTables = Watched(unlockTablesBase.value)
unlockTablesBase.subscribe(function(v) {
  if (!isEqual(v, unlockTables.value))
    unlockTables(v)
})

let personalUnlocksData = Computed(@() userstatUnlocks.value?.personalUnlocks ?? {})

let unlockLogs = Computed(@() (userstatUnlocks.value?.logs ?? []))

let allUnlocks = Computed(@() (userstatDescList.value?.unlocks ?? {})
  .map(function(u, _name) {
    let upd = {}
    if ((u?.personal ?? "") != "")
      upd.personalData <- personalUnlocksData.value?[u.name] ?? {}
    if ("stages" in u)
      upd.stages <- u.stages.map(@(stage) stage.__merge({ progress = (stage?.progress ?? 1).tointeger() }))
    return u.__merge(upd)
  }))

let activeUnlocks = Computed(@() allUnlocks.value.filter(function(ud) {
  if (!(unlockTables.value?[ud?.table] ?? false) && ud?.type != "INDEPENDENT")
    return false
  if ("personalData" in ud)
    return isDebugPersonal.value || ud.personalData.len() > 0
  return true
}))

let unlocksSorted = Computed( function() {
  let list = activeUnlocks.value
  let res = []
  foreach (unlock in list)
    if (!unlock?.meta?.hideOnClient)
      res.append(unlock)
  return res
})

let function calcUnlockProgress(progressData, unlockDesc) {
  let res = clone emptyProgress
  let stage = progressData?.stage ?? 0
  res.stage = stage
  res.lastRewardedStage = progressData?.lastRewardedStage ?? 0
  res.hasReward = stage > res.lastRewardedStage

  if (progressData?.progress != null && unlockDesc != null) {
    res.current = progressData.progress
    res.required = progressData.nextStage
    return res
  }

  let stageToShow = min(stage, unlockDesc?.stages.len() ?? 0)
  res.required = (unlockDesc?.stages[stageToShow].progress || 1).tointeger()
  if (stage > 0) {
    let isLastStageCompleted = (unlockDesc?.periodic != true) && (stage >= stageToShow)
    res.isCompleted = isLastStageCompleted || res.hasReward
    res.isFinished = isLastStageCompleted && !res.hasReward
    res.current = res.required
  }
  return res
}

let unlockProgress = Computed(function() {
  let progressList = userstatUnlocks.value?.unlocks ?? {}
  let unlockDataList = allUnlocks.value
  let allKeys = progressList.__merge(unlockDataList) //use only keys from it
  return allKeys.map(@(_, name) calcUnlockProgress(progressList?[name], unlockDataList?[name]))
})

let getUnlockProgress = @(unlockDesc) unlockProgress.value?[unlockDesc?.name] ?? (clone emptyProgress)

let mkRequirements = memoize(@(reqStr) reqStr.split("&").map(@(v) strip(v)).filter(@(v) v!=""))
let isUnlockAvailable = @(unlockProgressV, unlock)
  mkRequirements(unlock?.requirement ?? "")
    .findvalue(@(r) !(unlockProgressV?[r].isCompleted ?? false)) == null

console_register_command(function() {
    isDebugPersonal(!isDebugPersonal.value)
    console_print("Debug Personal tasks:", isDebugPersonal.value)
  },
  "unlocks.debugPersonalUnlocks")

return {
  allUnlocks
  unlockLogs
  activeUnlocks
  unlocksSorted
  unlockProgress
  emptyProgress = freeze(emptyProgress)
  getUnlockProgress
  isUnlockAvailable
  mkRequirements
  DAILY_TASK_KEY
}