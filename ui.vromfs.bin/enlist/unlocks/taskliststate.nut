from "%enlSqGlob/ui_library.nut" import *
let { hasEliteBattlePass } = require("%enlist/battlepass/eliteBattlePass.nut")
let {
  unlocksSorted, unlockProgress, emptyProgress, activeUnlocks
} = require("%enlSqGlob/userstats/unlocksState.nut")
let {
  receiveUnlockRewards, userstatUnlocks, userstatStats, rerollUnlock
} = require("%enlSqGlob/userstats/userstat.nut")

const BP_DAILY_POINTS = "battle_pass_daily_points"
const BP_DAILY_POINTS_PREM = "battle_pass_premium_daily_points"

let isRerollInProgress = Watched(false)

let dailyTasks = Computed(@() unlocksSorted.value
  .filter(@(u) u.table == "daily")
  .map(@(u) u.__merge(unlockProgress.value?[u.name] ?? emptyProgress))
  .sort(function(a, b) {
    return a.isFinished <=> b.isFinished
      || b.hasReward <=> a.hasReward
      || (a?.meta?.taskListPlace ?? -1) <=> (b?.meta?.taskListPlace ?? -1)
      || (a?.stages?[0]?.progress ?? 0) <=> (b?.stages?[0]?.progress ?? 0)
      || b.name <=> a.name
  }))

let dailyTasksByDifficulty = Computed(function() {
  let res = {
    easyTasks = []
    hardTasks = []
  }
  foreach (task in dailyTasks.value)
    if (task?.meta.core_unlock ?? false)
      res.easyTasks.append(task)
    else
      res.hardTasks.append(task)

  return res
})

let bpDailyTask = Computed(@() activeUnlocks.value
  .findvalue(@(unlock) unlock?.name == BP_DAILY_POINTS))

let bpDailyTaskPrem = Computed(@() activeUnlocks.value
  .findvalue(@(unlock) unlock?.name == BP_DAILY_POINTS_PREM))

let bpDailyTaskProgress = Computed(@()
  unlockProgress.value?[BP_DAILY_POINTS] ?? emptyProgress)

let bpDailyTaskPremProgress = Computed(@()
  unlockProgress.value?[BP_DAILY_POINTS_PREM] ?? emptyProgress)

let canTakeDailyTaskReward = Computed(@()
  hasEliteBattlePass.value || bpDailyTaskProgress.value?.stage in bpDailyTask.value?.stages)

let function receiveTaskRewards(task) {
  let uName = task.name
  let stage = userstatUnlocks.value?.unlocks[uName].stage ?? 0
  receiveUnlockRewards(uName, stage)
}

let achievementsList = Computed(function() {
  let progresses = unlockProgress.value
  return activeUnlocks.value
    .filter(@(u) u?.meta.achievement ?? false)
    .reduce(@(res, val) res.append(val.__merge(progresses?[val.name] ?? emptyProgress)), [])
    .sort(function(a, b) {
      return b.hasReward <=> a.hasReward
        || a.isFinished <=> b.isFinished
        || (a?.meta.taskListPlace ?? -1) <=> (b?.meta.taskListPlace ?? -1)
        || b.name <=> a.name
    })
})

let achievementsByTypes = Computed(function() {
  let res = {
    achievements = []
    challenges = []
  }
  foreach (unlock in achievementsList.value)
    if ((unlock?.ps4Id ?? 0).tointeger() > 0 || (unlock?.xboxId ?? 0).tointeger() > 0)
      res.achievements.append(unlock)
    else
      res.challenges.append(unlock)

  return res
})

let hasAchievementsReward = Computed(@()
  achievementsList.value.findindex(@(u) u.hasReward) != null)

let getLeftRerolls = @(unlockDesc, stats)
  stats?[unlockDesc?.table].freeRerollLeft ?? 0

let getTotalRerolls = @(unlockDesc, stats)
  stats?[unlockDesc?.table].freeRerollLimit

let function doRerollUnlock(unlockDesc) {
  if (getLeftRerolls(unlockDesc, userstatStats.value?.stats) <= 0 || isRerollInProgress.value)
    return

  isRerollInProgress(true)
  rerollUnlock(unlockDesc.name, function(_) {
    isRerollInProgress(false)
  })
}

return {
  dailyTasks
  dailyTasksByDifficulty
  bpDailyTask
  bpDailyTaskPrem
  achievementsList
  achievementsByTypes
  hasAchievementsReward
  bpDailyTaskProgress
  bpDailyTaskPremProgress
  receiveTaskRewards
  canTakeDailyTaskReward

  getLeftRerolls
  getTotalRerolls
  isRerollInProgress
  doRerollUnlock
}
