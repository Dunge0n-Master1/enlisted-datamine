import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let canChangeCockpitView = Watched(false)

ecs.register_es("cockpit_ui_es", {
  onInit    = @(_evt, _eid, comp) canChangeCockpitView(comp["cockpit__slitNodes"].len() > 1)
  onChange  = @(_evt, _eid, comp) canChangeCockpitView(comp["cockpit__slitNodes"].len() > 1)
  onDestroy = @(_evt, _eid, _comp) canChangeCockpitView(false)
},
{
  comps_track = [
    ["cockpit__slitNodes", ecs.TYPE_INT_LIST],
    ["cockpit__isAttached", ecs.TYPE_BOOL],
  ]
},
{ after = "vehicle_cockpit_slits_init" })

return {
  canChangeCockpitView = canChangeCockpitView
}