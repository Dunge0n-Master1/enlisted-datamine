from "%enlSqGlob/ui_library.nut" import *

let { isSquadNotEmpty, isInSquad } = require("%enlist/squad/squadState.nut")
let { unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { onlineSettingUpdated, settings } = require("%enlist/options/onlineSettings.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")

const NEWBIE_UNLOCK_ID = "not_a_new_player_unlock"
const SAVE_ID = "user/notNewbiePlayer"

let isDebugNewbie = nestWatched("isDebugNewbie", null)

let isNewbieUnlock = Computed(@() unlockProgress.value?[NEWBIE_UNLOCK_ID].isCompleted)

let isNewbieBase = Computed(function() {
  if (isInSquad.value && isSquadNotEmpty.value)
    return false
  return !(settings.value?[SAVE_ID] ?? isNewbieUnlock.value ?? false)
})

let function saveNewbie(_ = null) {
  if (SAVE_ID not in settings.value && isNewbieUnlock.value)
    settings.mutate(@(set) set[SAVE_ID] <- true)
}

isNewbieUnlock.subscribe(saveNewbie)
onlineSettingUpdated.subscribe(saveNewbie)

let isNewbie = Computed(@() isDebugNewbie.value ?? isNewbieBase.value)

console_register_command(function(val) {
  isDebugNewbie(val)
  console_print($"debugNewbie = {isDebugNewbie.value}, isNewbie = {isNewbie.value}")
}, "ui.debugNewbieSet")

return isNewbie