from "%enlSqGlob/ui_library.nut" import *

let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {curWeaponWeapType} = require("%ui/hud/state/hero_weapons.nut")
let {isRadioMode} = require("%ui/hud/state/enlisted_hero_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let tip = tipCmp({
  text = loc("tips/use_radio", "Use radio")
  inputId = "Human.Shoot"
})

let showTip = Computed(@() !inVehicle.value && !isRadioMode.value && curWeaponWeapType.value == "radio")

let function use_radio() {
  let children = showTip.value ? tip : null
  return {
    watch = [showTip]
    size=SIZE_TO_CONTENT
    children = children
  }
}

return use_radio
