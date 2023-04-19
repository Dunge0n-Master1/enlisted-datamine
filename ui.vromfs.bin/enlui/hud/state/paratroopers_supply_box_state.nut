import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *


let showParatroopersSupplyBoxTip = Watched(false)


ecs.register_es("paratroopers_supply_box_can_use_ui",
  {
    [["onInit", "onChange"]] = @(_, comp) showParatroopersSupplyBoxTip(comp.human_paratroopers_supply_box__selectedEid != ecs.INVALID_ENTITY_ID),
    onDestroy = @() showParatroopersSupplyBoxTip(false)
  },
  {
    comps_rq=["watchedByPlr"]
    comps_track=[["human_paratroopers_supply_box__selectedEid", ecs.TYPE_EID]]
  }
)


return { showParatroopersSupplyBoxTip }
