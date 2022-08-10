import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isBipodPlaceable = Watched(false)
let isBipodEnabled = Watched(false)

ecs.register_es("bipod_track_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      isBipodPlaceable.update(comp["bipod__placeable"])
      isBipodEnabled.update(comp["bipod__enabled"])
    }
    onDestroy = function(...) {
      isBipodPlaceable(false)
      isBipodEnabled(false)
    }
  },
  {
    comps_track=[["bipod__placeable", ecs.TYPE_BOOL], ["bipod__enabled", ecs.TYPE_BOOL]]
    comps_rq = ["hero"]
  }
)

return {
  isBipodPlaceable,
  isBipodEnabled
}
