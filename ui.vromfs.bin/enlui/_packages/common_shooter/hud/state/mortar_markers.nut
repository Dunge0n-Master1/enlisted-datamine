import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let mortarMarkers = Watched([])

let mortarMarkersQuery = ecs.SqQuery("mortarMarkersQuery", { comps_rq = ["mortar_marker"], comps_ro=[["transform", ecs.TYPE_MATRIX], ["type", ecs.TYPE_STRING]]})
let function updateMarkers(ignore=INVALID_ENTITY_ID) {
  let markers = []
  mortarMarkersQuery.perform(function(eid, comp) {
    if (eid != ignore)
      markers.append({pos=comp.transform.getcol(3), type=comp.type})
  })
  mortarMarkers(markers)
}

ecs.register_es("mortar_marker_ui_es",
  { onInit = @() updateMarkers()
    onDestroy = @(eid, _comp) updateMarkers(eid)
  },
  { comps_rq = ["mortar_marker"] },
  { tags = "gameClient" }
)

return mortarMarkers