import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let defValue = freeze({
  isInHatch = false,
  canHoldWeapon = false,
  isHoldingGunPassenger = false
})
let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")
let { isInHatch, canHoldWeapon, isHoldingGunPassenger } = watchedTable2TableOfWatched(state)

ecs.register_es("hold_gun_mode_hero_state_ui",{
  [["onChange", "onInit"]] = @(_, _eid, comp) stateSetValue({
    isInHatch = comp.human_vehicle__isInHatch
    canHoldWeapon = comp.human_vehicle__canHoldWeapon
    isHoldingGunPassenger = comp.human_vehicle__isHoldingGunPassenger
  }),
  onDestroy = @(...) stateSetValue(defValue)
}, {
  comps_track=[
    ["human_vehicle__isInHatch", ecs.TYPE_BOOL],
    ["human_vehicle__canHoldWeapon", ecs.TYPE_BOOL],
    ["human_vehicle__isHoldingGunPassenger", ecs.TYPE_BOOL]
  ],
  comps_rq=["hero"]
})

return {
  isInHatch
  canHoldWeapon
  isHoldingGunPassenger
}
