from "%enlSqGlob/ui_library.nut" import *

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
  size = flex()
  watch = [canChangeRespawnParams, needSpawnMenu, respawnsInBot]
  children = !needSpawnMenu.value || !canChangeRespawnParams.value ? null
    : respawnsInBot.value ? respawn_member
    : respawn_squad
}

return respawnBlock
