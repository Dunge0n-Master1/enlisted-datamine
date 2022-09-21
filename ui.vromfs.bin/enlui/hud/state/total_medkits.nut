import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let defValue = freeze({selfHealMedkits = 0, selfReviveMedkits = 0})
let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")
let { selfHealMedkits, selfReviveMedkits } = watchedTable2TableOfWatched(state)

ecs.register_es("total_medkits_ui",{
  [["onChange", "onInit"]] = @(_, _eid, comp) stateSetValue({
    selfHealMedkits = comp["total_kits__selfHeal"]
    selfReviveMedkits = comp["total_kits__selfRevive"]
  }),
  onDestroy = @(...) stateSetValue(defValue)
}, {
  comps_track=[["total_kits__selfHeal", ecs.TYPE_INT], ["total_kits__selfRevive", ecs.TYPE_INT]],
  comps_rq=["watchedByPlr"]
})

return {
  selfHealMedkits
  selfReviveMedkits
}
