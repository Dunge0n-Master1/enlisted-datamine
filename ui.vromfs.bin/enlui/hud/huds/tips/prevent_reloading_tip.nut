from "%enlSqGlob/ui_library.nut" import *

let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {curWeapon} = require("%ui/hud/state/hero_state.nut")
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
  && (curWeapon.value?.curAmmo ?? 0) > 0
  && curWeapon.value?.firingMode == "bolt_action"
  && curWeapon.value?.mods.scope.itemPropsId != null)

return @() {
  watch = isPreventReloadingVisible
  size = SIZE_TO_CONTENT
  children = isPreventReloadingVisible.value ? tip : null
}
