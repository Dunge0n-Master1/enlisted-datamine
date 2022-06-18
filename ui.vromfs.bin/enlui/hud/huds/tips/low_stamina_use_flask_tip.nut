from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { hasHeroFlask, flaskAffectApplied } = require("%ui/hud/state/flask.nut")
let { staminaUseFlask } = require("%ui/hud/state/stamina_es.nut")
let isFreeFall = require("%ui/hud/state/free_fall_state.nut")
let { isParachuteOpened } = require("%ui/hud/state/parachute_state.nut")
let { isUnderWater, isSwimming } = require("%ui/hud/state/hero_water_state.nut")
let { isBurning } = require("%ui/hud/state/burning_state_es.nut")
let { inVehicle, isPassenger } = require("%ui/hud/state/vehicle_state.nut")

let canUseFlask = Computed(@()
  hasHeroFlask.value
  && !isFreeFall.value
  && !isParachuteOpened.value
  && !isUnderWater.value
  && !isSwimming.value
  && !isBurning.value
  && (!inVehicle.value || isPassenger.value))

let tip = tipCmp({
  text = loc("tips/use_flask"),
  textColor = DEFAULT_TEXT_COLOR,
  inputId = "Inventory.UseFlask"
}.__update(body_txt))

return @() {
  flow = FLOW_HORIZONTAL
  watch = [staminaUseFlask, flaskAffectApplied, canUseFlask]
  children = canUseFlask.value && !flaskAffectApplied.value && staminaUseFlask.value ? tip : null
}
