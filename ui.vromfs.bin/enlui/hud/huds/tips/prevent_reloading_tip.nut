from "%enlSqGlob/ui_library.nut" import *

let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {curWeaponFiringMode, curWeaponHasScope, curWeaponAmmo} = require("%ui/hud/state/hero_weapons.nut")
let {isAiming} = require("%ui/hud/huds/crosshair_state_es.nut")
let {tipCmp} = require("tipComponent.nut")

let tip = tipCmp({
  inputId = "Human.Shoot"
  text = loc("tips/prevent_reloading")
  textColor = Color(100,140,200,110)
})

let isPreventReloadingVisible = Computed(@()
  isAiming.value
  && !inVehicle.value
  && curWeaponHasScope.value
  && curWeaponFiringMode.value == "bolt_action"
  && curWeaponAmmo.value > 0
)

return @() {
  watch = isPreventReloadingVisible
  size = SIZE_TO_CONTENT
  children = isPreventReloadingVisible.value ? tip : null
}
