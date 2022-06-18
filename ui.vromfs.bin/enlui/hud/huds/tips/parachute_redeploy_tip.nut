import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { isAlive } = require("%ui/hud/state/health_state.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")

let parachuterBattleareaRedeployAt = Watched(-1.0)

ecs.register_es("get_parachute_battlearea_redeploy_time",{
  [["onInit","onChange"]] = function(_eid,comp){
    parachuterBattleareaRedeployAt(comp["human_parachute_redeploy__redeployAtTime"])
  }
}, {comps_track=[["human_parachute_redeploy__redeployAtTime", ecs.TYPE_FLOAT]] comps_rq = ["watchedByPlr"]})

let redeployTip = tipCmp({
  text = loc("tips/parachute_battlearea_redeploy")
  textColor = Color(100,140,200,110)
})

let showTip = Computed(@()
  parachuterBattleareaRedeployAt.value > 0.0
  && showPlayerHuds.value
  && isAlive.value)

return @() {
  watch = showTip
  size = SIZE_TO_CONTENT
  children = showTip.value ? redeployTip : null
}
