from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { reachedArmyUnlocks } = require("armyUnlocksState.nut")


const SEEN_ID = "opened/armyProgress"

let seenArmyProgress = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let opened = settings.value?[SEEN_ID] ?? {}
  let unseen = reachedArmyUnlocks.value
  let unopened = reachedArmyUnlocks.value
    .filter(@(lvl, armyId) lvl > (opened?[armyId] ?? 0))

  return { opened, unseen, unopened }
})

let function markOpened(armyId, level) {
  settings.mutate(function(set) {
    set[SEEN_ID] <- (set?[SEEN_ID] ?? {}).__merge({ [armyId] = level })
  })
}

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      delete s[SEEN_ID]
  })
}, "meta.resetSeenArmyProgress")

return {
  seenArmyProgress
  markOpened
}
