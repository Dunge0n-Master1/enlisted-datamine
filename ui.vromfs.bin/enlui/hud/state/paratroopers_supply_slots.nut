import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let slots = Watched({})

ecs.register_es("paratroopers_supply_slots",
  {
    [["onInit", "onChange"]] = @(_eid, comp) slots(comp.respawner__paratroopersSupplySlotsInfo.getAll() ?? [])
  },
  {
    comps_track = [["respawner__paratroopersSupplySlotsInfo", ecs.TYPE_ARRAY]],
    comps_rq = ["localPlayer"]
  }
)

return slots