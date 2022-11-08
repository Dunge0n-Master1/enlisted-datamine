import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isAlive } = require("%ui/hud/state/health_state.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")

let redeployAt = Watched(-1.0)
let isParachuteDeployed = Watched(false)

ecs.register_es("get_parachute_battlearea_redeploy_time",{
  [["onInit","onChange"]] = function(_eid,comp){
    redeployAt(comp.redeploy__atTime)
    isParachuteDeployed(comp.parachuteDeployed != null)
  }
}, {
  comps_ro=[["parachuteDeployed", ecs.TYPE_TAG, null]]
  comps_track=[["redeploy__atTime", ecs.TYPE_FLOAT]]
  comps_rq = ["watchedByPlr"]
})

let redeployTip = @() tipCmp({
  text = isParachuteDeployed.value ? loc("tips/parachute_battlearea_redeploy") : loc("tips/outside_battle_area_redeploy")
  textColor = Color(100,140,200,110)
})

let showTip = Computed(@()
  redeployAt.value > 0.0
  && showPlayerHuds.value
  && isAlive.value)

return @() {
  watch = [showTip, isParachuteDeployed]
  size = SIZE_TO_CONTENT
  children = showTip.value ? redeployTip : null
}
