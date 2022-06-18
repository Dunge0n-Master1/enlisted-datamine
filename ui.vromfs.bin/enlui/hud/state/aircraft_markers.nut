import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {TEAM_UNASSIGNED} = require("team")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let aircraft_markers = Watched({})

let function deleteEid(eid){
  if (eid in aircraft_markers.value)
    aircraft_markers.mutate(function(v) {
      delete v[eid]
    })
}

ecs.register_es(
  "aircraft_markers_es",
  {
    [["onInit", "onChange"]] = function(_ect, eid, comp){
      if (!comp.isAlive || comp.team == TEAM_UNASSIGNED || !comp["hud_aircraft_marker__isVisible"])
        deleteEid(eid)
      else
        aircraft_markers.mutate(@(v) v[eid] <- {
          team         = comp.team,
          isIdentified = comp["hud_aircraft_marker__isIdentified"],
          isFriendly   = localPlayerTeam.value == comp.team
        })
    }
    onDestroy = @(_evt, eid, _comp ) deleteEid(eid)
  },
  {
    comps_rq = ["hud_aircraft_marker"]
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL, false],
      ["team", ecs.TYPE_INT, null],
      ["hud_aircraft_marker__isIdentified", ecs.TYPE_BOOL, true],
      ["hud_aircraft_marker__isVisible", ecs.TYPE_BOOL, true],
    ]
  }
)

return{
  aircraft_markers = aircraft_markers
}