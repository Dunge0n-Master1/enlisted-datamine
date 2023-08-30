from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { squadsCanSpawn, isSpectatorEnabled } = require("%ui/hud/state/respawnState.nut")

const SHOW_TIME = 15

let showTip = Watched(false)
let hideTip = @() showTip(false)
let isTipAvailable = keepref(Computed(@() isSpectatorEnabled.value && !squadsCanSpawn.value))

let tip = tipCmp({
  text = loc("respawn/no_spawn_squads")
}.__update(fontSub))

let function showNoRespawnReason(state) {
  if (!state)
    return

  showTip(true)
  gui_scene.resetTimeout(SHOW_TIME, hideTip)
}

isTipAvailable.subscribe(showNoRespawnReason)

let no_respawn_reason_tip = @() {
  watch = showTip
  text = showTip.value ? tip : null
}

return no_respawn_reason_tip