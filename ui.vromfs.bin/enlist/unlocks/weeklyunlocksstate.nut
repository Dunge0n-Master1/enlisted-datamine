from "%enlSqGlob/ui_library.nut" import *

let {
  unlockProgress, emptyProgress, allUnlocks
} = require("%enlSqGlob/userstats/unlocksState.nut")


let curFinishedWeeklyTasksCount = Watched(0)
let bpStarsAnimGen = Watched(0)

let weeklyTasksSortFunc = @(a, b)
  (b?.activity.active ?? false) <=> (a?.activity.active ?? false)
    || (a?.isFinished ?? false) <=> (b?.isFinished ?? false)
    || (a?.meta.taskListPlace ?? -1) <=> (b?.meta.taskListPlace ?? -1)
    || a.name <=> b.name

let weeklyTasks = Computed(function() {
  let progress = unlockProgress.value
  let unlocks = allUnlocks.value
    .filter(@(u) u?.meta.weekly_unlock ?? false)
    .map(@(u, key) u.__merge(progress?[key] ?? emptyProgress))
    .values()
    .sort(weeklyTasksSortFunc)

  return unlocks
})

let rewardWeeklyTask = Computed(@() weeklyTasks.value
  .findvalue(@(task) task.hasReward))

let getFinishedWeeklyTasksCount = @()
  weeklyTasks.value.filter(@(u) u?.isFinished ?? false).len()

let function saveFinishedWeeklyTasks() {
  curFinishedWeeklyTasksCount(getFinishedWeeklyTasksCount())
}

let needWeeklyTasksAnim = @()
  getFinishedWeeklyTasksCount() > curFinishedWeeklyTasksCount.value

let function triggerBPStarsAnim() {
  if (needWeeklyTasksAnim())
    bpStarsAnimGen(bpStarsAnimGen.value + 1)
}

return {
  weeklyTasks
  rewardWeeklyTask
  saveFinishedWeeklyTasks
  triggerBPStarsAnim
  needWeeklyTasksAnim
  bpStarsAnimGen
}
