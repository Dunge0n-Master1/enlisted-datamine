import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  mortarMarkersSet,
  mortarMarkersGetWatched,
  mortarMarkersUpdateEid,
  mortarMarkersDestroyEid
} = mkWatchedSetAndStorage("mortarMarkers")


ecs.register_es("mortar_marker_ui_es",
  {
    onInit = function(_, eid, comp) {
      mortarMarkersUpdateEid(eid, {type = comp["type"], pos = comp.transform.getcol(3)})
    }
    onDestroy = @(_, eid, _comp) mortarMarkersDestroyEid(eid)
  },
  { comps_rq = ["mortar_marker"]
    comps_ro = [["transform", ecs.TYPE_MATRIX], ["type", ecs.TYPE_STRING]]
  },
  { tags = "gameClient" }
)

return {
  mortarMarkersSet,
  mortarMarkersGetWatched,
}