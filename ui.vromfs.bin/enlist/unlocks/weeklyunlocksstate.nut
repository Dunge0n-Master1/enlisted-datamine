from "%enlSqGlob/ui_library.nut" import *

let {
  unlockProgress, emptyProgress, allUnlocks
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")


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

const WEEKLYTASKS_SEEN_ID = "seen/weeklytasks"

let seenWeeklyTasks = Computed(@() settings.value?[WEEKLYTASKS_SEEN_ID])

let unseenWeeklyTasks = Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  let seen = seenWeeklyTasks.value ?? {}
  let unseen = {}
  foreach (u in weeklyTasks.value)
    if ((u?.activity.active ?? false) && !(u?.isFinished ?? false) && u.name not in seen)
      unseen[u.name] <- true

  return unseen
})

let function markSeenWeeklyTasks(id) {
  if (!(seenWeeklyTasks.value?[id] ?? false))
    settings.mutate(function(set) {
      set[WEEKLYTASKS_SEEN_ID] <- (set?[WEEKLYTASKS_SEEN_ID] ?? {}).__merge({ [id] = true })
    })
}

let hasWeeklyTasksAlert = Computed(@()
  weeklyTasks.value.findindex(@(u) u?.hasReward ?? false) != null
    || unseenWeeklyTasks.value.len() > 0
)

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

console_register_command(@() settings.mutate(@(v) delete v[WEEKLYTASKS_SEEN_ID]), "meta.resetSeenWeeklyTasks")

return {
  weeklyTasks
  hasWeeklyTasksAlert
  unseenWeeklyTasks
  markSeenWeeklyTasks
  saveFinishedWeeklyTasks
  triggerBPStarsAnim
  needWeeklyTasksAnim
  bpStarsAnimGen
}
