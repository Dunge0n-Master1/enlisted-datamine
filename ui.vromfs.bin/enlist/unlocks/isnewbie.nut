from "%enlSqGlob/ui_library.nut" import *

let { squadMembers, isInSquad } = require("%enlist/squad/squadState.nut")
let { unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")

let isDebugNewbie = Watched(null)

let isNewbieBase = Computed(function() {
  if (isInSquad.value && squadMembers.value.len() > 1)
    return false
  return !(unlockProgress.value?["not_a_new_player_unlock"].isCompleted ?? false)
})

let isNewbie = Computed(@() isDebugNewbie.value ?? isNewbieBase.value)

console_register_command(function(val) {
  isDebugNewbie(val)
  console_print($"debugNewbie = {isDebugNewbie.value}, isNewbie = {isNewbie.value}")
}, "ui.debugNewbieSet")

return isNewbie
