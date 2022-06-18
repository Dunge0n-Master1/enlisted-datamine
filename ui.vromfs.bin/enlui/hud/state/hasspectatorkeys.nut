from "%enlSqGlob/ui_library.nut" import *

let { isSpectator } = require("%ui/hud/state/spectator_state.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let {teammatesAliveNum} = require("%ui/hud/state/human_teammates.nut")

let hasSpectatorKeys = Computed(@() isSpectator.value && showPlayerHuds.value && teammatesAliveNum.value > 1)

return hasSpectatorKeys