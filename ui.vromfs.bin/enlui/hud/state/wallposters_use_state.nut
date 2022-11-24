from "%enlSqGlob/ui_library.nut" import *

let { isDowned, isAlive } = require("%ui/hud/state/health_state.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { isBinocularMode } = require("%ui/hud/state/binocular.nut")

let canUseWallposter = Computed(@() isAlive.value
  && (controlledHeroEid.value == watchedHeroEid.value)
  && !isDowned.value
  && !inVehicle.value
  && !isBinocularMode.value)

return {
  canUseWallposter
}