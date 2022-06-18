import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let selfHealMedkits = Watched(0)
let selfReviveMedkits = Watched(0)

let function medkitsOnCountChange(_eid, comp) {
  selfHealMedkits(comp["total_kits__selfHeal"])
  selfReviveMedkits(comp["total_kits__selfRevive"])
}

let function medkitsOnDestroy() {
  selfHealMedkits(0)
  selfReviveMedkits(0)
}

ecs.register_es("total_medkits_ui",{
  [["onChange", "onInit"]] = medkitsOnCountChange,
  [ecs.EventEntityDestroyed] = medkitsOnDestroy
}, {
  comps_track=[["total_kits__selfHeal", ecs.TYPE_INT], ["total_kits__selfRevive", ecs.TYPE_INT]],
  comps_rq=["watchedByPlr"]
})

return {
  selfHealMedkits
  selfReviveMedkits
}
