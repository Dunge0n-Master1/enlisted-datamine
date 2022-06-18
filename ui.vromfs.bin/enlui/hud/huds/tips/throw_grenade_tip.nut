from "%enlSqGlob/ui_library.nut" import *

let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {curWeapon} = require("%ui/hud/state/hero_state.nut")
let {isDowned} = require("%ui/hud/state/health_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")

let tip = tipCmp({
  text = loc("tips/throw_grenade", "Throw grenade")
  inputId = "Human.Shoot"
})

let function throw_grenade() {
  local children = null
  if (showPlayerHuds.value && !inVehicle.value && curWeapon.value?.grenadeType != null && !isDowned.value) {
    children = tip
  }
  return {
    watch = [inVehicle, curWeapon, showPlayerHuds, isDowned]
    size=SIZE_TO_CONTENT
    children = children
  }
}

return throw_grenade
