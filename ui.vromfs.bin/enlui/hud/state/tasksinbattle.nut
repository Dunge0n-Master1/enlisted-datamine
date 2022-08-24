from "%enlSqGlob/ui_library.nut" import *
let {
  unlocksSorted, emptyProgress, unlockProgress, DAILY_TASK_KEY
} = require("%enlSqGlob/userstats/unlocksState.nut")
let statsInGame = require("%ui/hud/state/userstatStateInBattle.nut")

let inGameModes = Computed(function(prev) {
  let res = {}
  foreach(mode in statsInGame.value?.modes ?? [])
    res[mode] <- true
  return isEqual(prev, res) ? prev : res
})
let isEvent = Computed(@() inGameModes.value?.endgame_events ?? false)

let function appendAllSteps(res, unlockName, step, byRequirement) {
  if (unlockName not in byRequirement)
    return step - 1
  local totalSteps = step
  foreach(unlock in byRequirement[unlockName]) {
    let curTotal = appendAllSteps(res, unlock.name, step + 1, byRequirement)
    res.append(unlock.__merge({ step, totalSteps = curTotal }))
    totalSteps = max(totalSteps, curTotal)
  }
  return totalSteps
}

let battleUnlocks = Computed(function() {
  let filterFunc = isEvent.value ? @(u) u?.meta.event_unlock ?? false
    : @(u) (u?.meta.isVisibleInBattle ?? true) && (u.table == DAILY_TASK_KEY || (u?.meta.weekly_unlock ?? false))
  let unlocks = unlocksSorted.value.filter(filterFunc)
  if (!isEvent.value)
    return unlocks

  let byRequirement = {}
  foreach(u in unlocks) {
    let requirement = u?.requirement ?? ""
    if (requirement not in byRequirement)
      byRequirement[requirement] <- []
    byRequirement[requirement].append(u)
  }

  let res = []
  appendAllSteps(res, "", 1, byRequirement)
  return res
})

let battleProgressBase = Computed(function() {
  let res = {}
  foreach(unlock in battleUnlocks.value)
    res[unlock.name] <- unlockProgress.value?[unlock.name] ?? emptyProgress
  return res
})

let battleUnlocksWithProgress = Computed(function() {
  let stats = statsInGame.value
  let modes = inGameModes.value
  return battleUnlocks.value.map(function(unlock) {
    let progress = battleProgressBase.value?[unlock.name] ?? emptyProgress
    let { stat = null, mode = null } = unlock?.meta
    if (!(modes?[mode] ?? false))
      return unlock.__merge(progress)

    local { current = 0, required = 1 } = progress
    let statToCheck = typeof stat == "array" ? stat : [stat]
    let inGameStat = statToCheck.reduce(@(res, s) (stats?[s] ?? 0) + res, 0)
    current = min(current + inGameStat, required)
    return unlock.__merge(progress, { current, isCompleted = current >= required })
  })
})

return Computed(@() battleUnlocksWithProgress.value
  .filter(@(u) !(u?.isFinished ?? false))
  .sort(@(a, b) b.hasReward <=> a.hasReward
      || (a?.meta?.taskListPlace ?? -1) <=> (b?.meta?.taskListPlace ?? -1)
      || (a?.stages?[0]?.progress ?? 0) <=> (b?.stages?[0]?.progress ?? 0)
      || b.name <=> a.name)
)