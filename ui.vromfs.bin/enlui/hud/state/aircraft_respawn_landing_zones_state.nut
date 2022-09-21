import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")
let {
  landing_zones_Set,
  landing_zones_GetWatched,
  landing_zones_UpdateEid,
  landing_zones_DestroyEid,
} = mkWatchedSetAndStorage("landing_zones_")

ecs.register_es("aircraft_respawn_landing_zones_ui_state_es",
  {
    [["onChange", "onInit"]] = function(_, eid, comp) {
      if (comp.landing_zone__isAvailable)
        landing_zones_UpdateEid(eid, {
          eid
          icon    = comp.zone__icon
          radius  = comp.sphere_zone__radius
        })
      else
        landing_zones_DestroyEid(eid)
    }
    onDestroy = @(_, eid) landing_zones_DestroyEid(eid)
  },
  {
    comps_ro = [
      ["zone__icon", ecs.TYPE_STRING, ""],
      ["sphere_zone__radius", ecs.TYPE_FLOAT, 0]
    ]
    comps_track = [
      ["landing_zone__isAvailable", ecs.TYPE_BOOL]
    ]
    comps_rq = ["landingZone"]
  },
  { tags="gameClient" }
)

return {
  landing_zones_GetWatched,
  landing_zones_Set
}
