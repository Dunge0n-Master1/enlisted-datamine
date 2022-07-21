from "%enlSqGlob/ui_library.nut" import *

let {
  unlocksSorted, emptyProgress, unlockProgress, allUnlocks, DAILY_TASK_KEY
} = require("%enlSqGlob/userstats/unlocksState.nut")
let statsInGame = require("%ui/hud/state/userstatStateInBattle.nut")

let isEvent = Computed(@() statsInGame.value?.modes.contains("endgame_events") ?? false)

let isActiveWeeklyTask = @(u) (u?.meta.weekly_unlock ?? false)
  && !(u?.isFinished ?? false)

let getTaskFilter = @(u) (u?.meta.isVisibleInBattle ?? true) && isEvent.value
  ? (u?.meta.event_unlock ?? false)
  : u.table == DAILY_TASK_KEY || isActiveWeeklyTask(u)

let unlockProgressInBattle = Computed(function() {
  return unlockProgress.value.map(function(progress, name) {
    let { stat = null, mode = null } = allUnlocks.value?[name].meta
    if (mode != null && statsInGame.value?.modes.contains(mode)) {
      let statToCheck = typeof stat == "array" ? stat : [stat]
      let inGameStat = statToCheck.reduce(@(res, s) (statsInGame.value?[s] ?? 0) + res, 0)
      let current = min((progress?.current ?? 0) + inGameStat, progress.required)
      return progress.__merge({current, isCompleted = current >= progress.required})
    }
    return progress
  })
})

let getNextUnlock = @(unlockName, unlocks)
  unlocks.findvalue(@(u) (u?.requirement ?? "") == unlockName)

let eventUnlocks = Computed(function() {
  let progresses = unlockProgress.value
  let unlocks = unlocksSorted.value.filter(@(u) u?.meta.event_unlock ?? false)
  let startUnlocks = unlocks.filter(@(u) (u?.requirement ?? "") == "")
    .sort(@(a,b) a?.meta.taskListPlace == null ? 1
      : b?.meta.taskListPlace == null ? -1
      : a.meta.taskListPlace <=> b.meta.taskListPlace)
  let res = []
  foreach (unlock in startUnlocks) {
    local step = 1
    res.append(unlock.__merge({ step }, progresses?[unlock.name] ?? emptyProgress))
    local nextUnlock = getNextUnlock(unlock.name, unlocks)
    while (nextUnlock != null) {
      step++
      res.append(nextUnlock.__merge({ step }, progresses?[nextUnlock.name] ?? emptyProgress))
      nextUnlock = getNextUnlock(nextUnlock.name, unlocks)
    }
  }

  local totalSteps = 1
  for (local i = res.len() - 1; i >= 0; i--) {
    let { step } = res[i]
    totalSteps = max(totalSteps, step)
    res[i].totalSteps <- totalSteps
    if (step == 1)
      totalSteps = 1
  }
  return res
})

return Computed(@() (isEvent.value ? eventUnlocks.value : unlocksSorted.value)
  .map(@(u) u.__merge(unlockProgressInBattle.value?[u.name] ?? emptyProgress))
  .filter(@(u) getTaskFilter(u))
  .sort(function(a, b) {
    return a.isFinished <=> b.isFinished
      || b.hasReward <=> a.hasReward
      || (a?.meta?.taskListPlace ?? -1) <=> (b?.meta?.taskListPlace ?? -1)
      || (a?.stages?[0]?.progress ?? 0) <=> (b?.stages?[0]?.progress ?? 0)
      || b.name <=> a.name
  })
)