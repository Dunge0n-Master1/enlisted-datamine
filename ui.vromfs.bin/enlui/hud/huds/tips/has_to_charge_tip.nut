from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { curWeaponChargeTime } = require("%ui/hud/state/hero_weapons.nut")

const TIP_SHOW_TIME = 5

let hasToCharge = Computed(@() curWeaponChargeTime.value > 0)
let needToShowTip = Watched(false)

hasToCharge.subscribe(@(v) v ? needToShowTip(true) : needToShowTip(false))

let chargeToShootTip = tipCmp({
  text = loc("hint/chargeToShootTip")
  inputId = "Human.Shoot"
  style = {onAttach = @() gui_scene.setTimeout(TIP_SHOW_TIME, @() needToShowTip(false))}
}.__update(body_txt))

let has_to_charge_tip = @() {
  watch = [hasToCharge, needToShowTip]
  children = hasToCharge.value && needToShowTip.value ? chargeToShootTip : null
}

return has_to_charge_tip