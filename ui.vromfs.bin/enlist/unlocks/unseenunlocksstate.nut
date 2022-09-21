from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { achievementsList } = require("taskListState.nut")
let { weeklyTasks } = require("weeklyUnlocksState.nut")


enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

const SEEN_ID = "seen/unlocks"
const WEEKLYTASKS_SEEN_ID = "seen/weeklytasks"

let function moveWeeklyUnlocks() {
  if (WEEKLYTASKS_SEEN_ID not in settings.value)
    return

  let seenData = settings.value[WEEKLYTASKS_SEEN_ID]
  let res = {}
  foreach (name, val in seenData) {
    let newVal = type(val) == "bool" ? SeenMarks.SEEN
      : type(val) == "integer" ? val
      : null
    if (newVal != null)
      res[name] <- newVal
  }
  settings.mutate(function(set) {
    set[SEEN_ID] <- res
    delete set[WEEKLYTASKS_SEEN_ID]
  })
}

// compatibility from 03/08/2022
settings.subscribe(function(v) {
  if (WEEKLYTASKS_SEEN_ID in v)
    gui_scene.resetTimeout(0.1, moveWeeklyUnlocks)
})

let getSeenStatus = @(val) val == null ? SeenMarks.NOT_SEEN : val

let seenUnlocks = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let opened = {}
  let seen = {}
  foreach(key, seenData in settings.value?[SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      seen[key] <- true
  }

  let unopenedAchievements = {}
  foreach (unlock in achievementsList.value.filter(@(u) u.hasReward))
    if (unlock.name not in opened)
      unopenedAchievements[unlock.name] <- true

  let unseenWeeklyTasks = {}
  let unopenedWeeklyTasks = {}
  foreach (unlock in weeklyTasks.value) {
    let { name, isFinished = false, activity = null } = unlock
    let { active = false } = activity
    if (!active || isFinished)
      continue

    if (name not in seen)
      unseenWeeklyTasks[name] <- true
    if (name not in opened)
      unopenedWeeklyTasks[name] <- true
  }

  return {
    opened
    seen
    unopenedAchievements
    unseenWeeklyTasks
    unopenedWeeklyTasks
  }
})

let hasUnopenedAchievements = Computed(@()
  (seenUnlocks.value?.unopenedAchievements ?? {}).len() > 0)

let hasUnopenedWeeklyTasks = Computed(@()
  (seenUnlocks.value?.unopenedWeeklyTasks ?? {}).len() > 0)

let hasUnseenWeeklyTasks = Computed(@()
  weeklyTasks.value.findindex(@(u) u?.hasReward ?? false) != null
    || (seenUnlocks.value?.unseenWeeklyTasks ?? {}).len() > 0)

let function markUnlocksOpened(names) {
  if (names.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      foreach(name in names)
        saved[name] <- SeenMarks.OPENED
      set[SEEN_ID] <- saved
    })
}

let function markUnlockSeen(id) {
  if (id not in seenUnlocks.value?.seen)
    settings.mutate(function(set) {
      set[SEEN_ID] <- (set?[SEEN_ID] ?? {}).__merge({ [id] = SeenMarks.SEEN })
    })
}

console_register_command(@() settings.mutate(@(v) delete v[SEEN_ID]), "meta.resetSeenUnlocks")

return {
  seenUnlocks
  markUnlockSeen
  markUnlocksOpened
  hasUnopenedAchievements
  hasUnopenedWeeklyTasks
  hasUnseenWeeklyTasks
}
