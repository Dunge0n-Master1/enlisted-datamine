from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { squadsCanSpawn, isSpectatorEnabled } = require("%ui/hud/state/respawnState.nut")

const hideAfter = 15

let reason = Watched(null)

let function showNoRepsawnReason(val) {
  reason(val && !squadsCanSpawn.value
      ? loc("respawn/no_spawn_squads")
      : null)
  gui_scene.setTimeout(hideAfter, @() reason(null))
}

isSpectatorEnabled.subscribe(showNoRepsawnReason)

let no_respawn_reason_tip = @() {
  rendObj = ROBJ_TEXT
  text = reason.value
  watch = reason
  margin = hdpx(20)
}.__update(sub_txt)

return no_respawn_reason_tip