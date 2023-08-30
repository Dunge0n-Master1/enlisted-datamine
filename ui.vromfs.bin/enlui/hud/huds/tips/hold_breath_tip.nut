from "%enlSqGlob/ui_library.nut" import *

let {curWeaponAmmo} = require("%ui/hud/state/hero_weapons.nut")
let {isHoldBreath, isHoldBreathAvailable} = require("%ui/hud/state/breath_state.nut")
let isMachinegunner = require("%ui/hud/state/machinegunner_state.nut")
let {tipCmp} = require("tipComponent.nut")

let tip = tipCmp({
  inputId = "Human.HoldBreath"
  text = loc("tips/hold_breath_to_aim")
  textColor = Color(100,140,200,110)
})

let showHoldBrief = Computed(@()
  isHoldBreathAvailable.value
  && !isMachinegunner.value
  && !isHoldBreath.value
  && (curWeaponAmmo.value > 0)
)

return @() {
  watch = showHoldBrief
  size = SIZE_TO_CONTENT
  children = showHoldBrief.value ? tip : null
}
