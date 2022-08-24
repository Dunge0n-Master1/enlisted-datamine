import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let hasFreeSeat = Watched(true)

ecs.register_es("ui_vehicle_free_seat_es",
  {
    [["onChange", "onInit"]] = @(_eid, comp) hasFreeSeat(comp["selected_vehicle__hasFreeSeat"])
  },
  {
    comps_track = [["selected_vehicle__hasFreeSeat", ecs.TYPE_BOOL]],
    comps_rq = ["hero"]
  }
)

return {
  hasFreeSeat
}