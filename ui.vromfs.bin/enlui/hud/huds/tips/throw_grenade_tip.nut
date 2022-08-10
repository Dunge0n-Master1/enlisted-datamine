from "%enlSqGlob/ui_library.nut" import *

let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {curWeaponIsGrenade, isThrowMode} = require("%ui/hud/state/hero_weapons.nut")
let {isDowned} = require("%ui/hud/state/health_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let {isThrowDistanceIncreased} = require("%ui/hud/state/enlisted_hero_state.nut")

let tipNormalThrow = tipCmp({
  text = loc("tips/throw_grenade", "Throw grenade")
  inputId = "Human.Shoot"
})

let tipLongThrow = tipCmp({
  text = loc("tips/throw_grenade_long", "Throw grenade (Throw range increased)")
  inputId = "Human.Shoot"
})

let tipFastLongThrow = tipCmp({
  text = loc("tips/throw_grenade_increased_range", "Throw range increased")
})

let showTip = Computed(@() showPlayerHuds.value && !inVehicle.value && !isDowned.value)
let function throw_grenade() {
  return {
    watch = [showTip, isThrowDistanceIncreased, curWeaponIsGrenade, isThrowMode]
    children = !showTip.value
      ? null
      : curWeaponIsGrenade.value
        ? isThrowDistanceIncreased.value
          ? tipLongThrow
          : tipNormalThrow
        : isThrowMode.value
          ? isThrowDistanceIncreased.value
            ? tipFastLongThrow
            : null
          : null
  }
}

return throw_grenade
