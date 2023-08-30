from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { isSpectator, spectatingPlayerName } = require("%ui/hud/state/spectator_state.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")

let spectatingName = Computed(@() isSpectator.value && spectatingPlayerName.value != null
  ? spectatingPlayerName.value
  : null)

let function spectatorMode_tip() {
  let res = { watch = [spectatingName, isReplay] }
  if (isReplay.value || spectatingName.value == null)
    return res
  return res.__update({
    rendObj = ROBJ_TEXT
    text = spectatingName.value != null
      ? loc("hud/spectator_target", {user = spectatingName.value})
      : null
    watch = spectatingName
    margin = hdpx(20)
    fontFx = FFT_GLOW
    fontFxColor = 0xCC000000
    fontFxFactor = min(16, hdpx(16))
  }.__update(fontSub))
}

return spectatorMode_tip
