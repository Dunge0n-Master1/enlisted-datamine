from "%enlSqGlob/ui_library.nut" import *

let {
  needSpawnMenu, updateSpawnSquadId, canChangeRespawnParams, respawnsInBot
} = require("%ui/hud/state/respawnState.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let respawn_member = isNewDesign.value
  ? require("%ui/hud/menus/respawn/soldiersRespawn.ui.nut")
  : require("respawn_member.ui.nut")
let respawn_squad = isNewDesign.value
  ? require("%ui/hud/menus/respawn/squadRespawn.ui.nut")
  : require("respawn_squad.ui.nut")

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
