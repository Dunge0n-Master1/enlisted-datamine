from "%enlSqGlob/ui_library.nut" import *

let { isRadioMode } = require("%ui/hud/state/enlisted_hero_state.nut")
let { isMortarMode } = require("%ui/hud/state/mortar.nut")
let { isAlive, isDowned } = require("%ui/hud/state/health_state.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { hasFreeSeat } = require("%ui/hud/state/vehicle_free_seat_state.nut")

let canUseVehicle = Computed(@() isAlive.value && !isDowned.value && !isMortarMode.value &&
    !isRadioMode.value && !inVehicle.value)

let function vehicleFreeSeatTip() {
  let res = { watch = [canUseVehicle, hasFreeSeat] }

  if (!canUseVehicle.value)
    return res

  if (!hasFreeSeat.value)
    return res.__update({
      children = tipCmp({
        text = loc("hud/vehcile_locked_by_seat_taken")
        textColor = DEFAULT_TEXT_COLOR
      })
    })

  return res
}

return vehicleFreeSeatTip