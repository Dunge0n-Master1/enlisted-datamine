from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { curWeaponChargeTime } = require("%ui/hud/state/hero_weapons.nut")

const TIP_SHOW_TIME = 5

let hasToCharge = Computed(@() curWeaponChargeTime.value > 0)
let needToShowTip = Watched(false)
let hideTip = @() needToShowTip(false)

hasToCharge.subscribe(@(v) v ? needToShowTip(true) : needToShowTip(false))

let chargeToShootTip = tipCmp({
  text = loc("hint/chargeToShootTip")
  inputId = "Human.Shoot"
  style = {
    onAttach = @() gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
  }
}.__update(fontBody))

let has_to_charge_tip = @() {
  watch = [hasToCharge, needToShowTip]
  children = hasToCharge.value && needToShowTip.value ? chargeToShootTip : null
}

return has_to_charge_tip