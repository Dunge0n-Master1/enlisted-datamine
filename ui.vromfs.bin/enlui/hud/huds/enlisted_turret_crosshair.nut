from "%enlSqGlob/ui_library.nut" import *

let gunnerCrosshair = require("%ui/hud/huds/turret_crosshair.nut")
let commanderCrosshair = require("%ui/hud/huds/commander_crosshair.nut")
let {inTank, isGunner} = require("%ui/hud/state/vehicle_state.nut")

return function(){
  return {
    watch = [inTank,isGunner]
    children = (!inTank.value || isGunner.value) ? gunnerCrosshair : commanderCrosshair
  }
}