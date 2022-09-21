import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isAlive } = require("%ui/hud/state/health_state.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")

let planeRedeployAt = Watched(-1.0)

ecs.register_es("plane_redeploy_tip_state_ui",{
  [["onInit","onChange"]] = @(_eid, comp) planeRedeployAt(comp.plane_landing__repairAtTime)
  function onDestroy(...) { planeRedeployAt(-1.0) }
}, {comps_track=[["plane_landing__repairAtTime", ecs.TYPE_FLOAT]] comps_rq = ["vehicleWithWatched"]})

let redeployTip = tipCmp({
  text = loc("tips/plane_redeploy")
  textColor = Color(100,140,200,110)
})

let showTip = Computed(@()
  planeRedeployAt.value > 0.0
  && showPlayerHuds.value
  && isAlive.value)

return @() {
  watch = showTip
  size = SIZE_TO_CONTENT
  children = showTip.value ? redeployTip : null
}
