from "%enlSqGlob/ui_library.nut" import *

let achievements = require("%xboxLib/impl/achievements.nut")
let {unlockProgress, unlocksSorted, getUnlockProgress} = require("%enlSqGlob/userstats/unlocksState.nut")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX_ACHIEVEMENTS] ")


let function update_xbox_achievements(_) {
  logX("update_xbox_achievements")

  if (unlockProgress.value.len() == 0) {
    logX("Empty unlock progress. Skipping")
    return
  }

  local unlocks = []
  foreach (unlockDesc in unlocksSorted.value) {
    let progress = getUnlockProgress(unlockDesc, unlockProgress.value)
    let id = unlockDesc.xboxId
    let percents = (100.0 * (progress.current * 1.0 / progress.required)).tointeger()
    unlocks.append({id = id, progress = percents})
  }

  achievements.set_progress_batch(unlocks)
}


unlockProgress.subscribe(update_xbox_achievements)
unlocksSorted.subscribe(update_xbox_achievements)
