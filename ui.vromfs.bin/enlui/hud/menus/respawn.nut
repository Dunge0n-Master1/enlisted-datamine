from "%enlSqGlob/ui_library.nut" import *
let { isGamepad } = require("%ui/control/active_controls.nut")

let {
  needSpawnMenu, updateSpawnSquadId, canChangeRespawnParams, respawnsInBot
} = require("%ui/hud/state/respawnState.nut")
let respawn_member = require("respawn_member.ui.nut")
let respawn_squad = require("respawn_squad.ui.nut")

needSpawnMenu.subscribe(function(v) {
  if (v)
    updateSpawnSquadId()
})

let respawnBlock = @() {
  watch = [canChangeRespawnParams, needSpawnMenu, respawnsInBot, isGamepad]
  size = flex()
  padding = isGamepad.value ? [0, 0, hdpx(30), 0] : 0
  children = !needSpawnMenu.value || !canChangeRespawnParams.value ? null
    : respawnsInBot.value ? respawn_member
    : respawn_squad
}

return respawnBlock
