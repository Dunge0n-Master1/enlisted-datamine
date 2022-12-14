import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let {controlledHeroEid} = require("%ui/hud/state/controlled_hero.nut")
let {watchedHeroPlayerEid} = require("%ui/hud/state/watched_hero.nut")
let {localPlayerSpecTarget} = require("%ui/hud/state/local_player.nut")

let isSpectator = Computed(@() localPlayerSpecTarget.value != ecs.INVALID_ENTITY_ID && localPlayerSpecTarget.value!=controlledHeroEid.value)
//Computed(@() watchedHeroEid.value != controlledHeroEid.value)
let spectatingPlayerName = Computed(@() remap_nick(ecs.obsolete_dbg_get_comp_val(watchedHeroPlayerEid.value, "name", null)))

return {
  isSpectator
  spectatingPlayerName
  localPlayerSpecTarget
}