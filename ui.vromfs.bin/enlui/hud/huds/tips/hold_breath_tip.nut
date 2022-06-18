from "%enlSqGlob/ui_library.nut" import *

let {curWeapon} = require("%ui/hud/state/hero_state.nut")
let {isHoldBreath} = require("%ui/hud/state/breath_state.nut")
let {isAiming} = require("%ui/hud/huds/crosshair_state_es.nut")
let isMachinegunner = require("%ui/hud/state/machinegunner_state.nut")
let {tipCmp} = require("tipComponent.nut")

let tip = tipCmp({
  inputId = "Human.HoldBreath"
  text = loc("tips/hold_breath_to_aim")
  textColor = Color(100,140,200,110)
})

let showHoldBrief = Computed(@()
  isAiming.value
  && !isMachinegunner.value
  && !isHoldBreath.value
  && (curWeapon.value?.curAmmo ?? 0) > 0)

return @() {
  watch = showHoldBrief
  size = SIZE_TO_CONTENT
  children = showHoldBrief.value ? tip : null
}
