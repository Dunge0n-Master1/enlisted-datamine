from "%enlSqGlob/ui_library.nut" import *

let ps4 = require("ps4")
let {unlockProgress, unlocksSorted, getUnlockProgress} = require("%enlSqGlob/userstats/unlocksState.nut")

let function updatePS4Achievements(_) {
  if (unlockProgress.value.len() == 0)
    return

  foreach (unlockDesc in unlocksSorted.value) {
    local trophy_id = unlockDesc.ps4Id.tointeger()
    if (trophy_id > 0) {// valid gaijin <-> psn mapping

      trophy_id -= 1 // psn trophies ids begin from 0, adjust
      let progress = getUnlockProgress(unlockDesc)
      let completed = progress.current >= progress.required
      let unlocked = ps4.is_trophy_unlocked(trophy_id)
      if (completed && !unlocked)
        ps4.unlock_trophy(trophy_id)
    }
  }
}

unlockProgress.subscribe(updatePS4Achievements)
unlocksSorted.subscribe(updatePS4Achievements)
