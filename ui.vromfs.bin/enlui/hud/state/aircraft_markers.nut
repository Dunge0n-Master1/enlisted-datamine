import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {TEAM_UNASSIGNED} = require("team")
let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  aircraft_markers_Set,
  aircraft_markers_GetWatched,
  aircraft_markers_UpdateEid,
  aircraft_markers_DestroyEid
} = mkWatchedSetAndStorage("aircraft_markers_")


ecs.register_es(
  "aircraft_markers_es",
  {
    [["onInit", "onChange"]] = function(_ect, eid, comp){
      if (!comp.isAlive || comp.team == TEAM_UNASSIGNED || !comp["hud_aircraft_marker__isVisible"])
        aircraft_markers_DestroyEid(eid)
      else
        aircraft_markers_UpdateEid(eid, {
          team         = comp.team,
          clampToBorder = comp.hud_aircraft_marker__clampToBorder,
          isIdentified = comp["hud_aircraft_marker__isIdentified"],
        })
    }
    onDestroy = @(_evt, eid, _comp ) aircraft_markers_DestroyEid(eid)
  },
  {
    comps_rq = ["hud_aircraft_marker"]
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL, false],
      ["team", ecs.TYPE_INT, null],
      ["hud_aircraft_marker__clampToBorder", ecs.TYPE_BOOL, false],
      ["hud_aircraft_marker__isIdentified", ecs.TYPE_BOOL, true],
      ["hud_aircraft_marker__isVisible", ecs.TYPE_BOOL, true],
    ]
  }
)

return{
  aircraft_markers_Set,
  aircraft_markers_GetWatched,
}