import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { localPlayerEid, localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { TEAM_UNASSIGNED } = require("team")

let user_points = Watched({})

ecs.register_es("user_points_ui_es",
  {[["onInit", "onChange"]] = function(eid, comp){
      user_points.mutate(function(v) {
        if (comp.team != TEAM_UNASSIGNED && comp.team != localPlayerTeam.value)
          return

        let target = comp["target"]
        let image = ecs.obsolete_dbg_get_comp_val(target, "building_menu__image", "building_wall")
        let res = {type = comp["hud_marker__type"], image = image, visible_distance = comp["hud_marker__visible_distance"]}
        if (comp["userPointOwner"]!=INVALID_ENTITY_ID)
          res.byLocalPlayer <- comp["userPointOwner"]  == localPlayerEid.value
        if (comp.userPointCustomIcon != "")
          res.customIcon <- Picture($"ui/skin#{comp.userPointCustomIcon}.svg")
        v[eid] <- res
      })
    },
    function onDestroy(eid, _comp){
      if (eid in user_points.value)
        user_points.mutate(@(v) delete v[eid])
    }
  },
  {
    comps_ro = [
      ["userPointOwner", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["userPointCustomIcon", ecs.TYPE_STRING, ""],
      ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["target", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["hud_marker__visible_distance", ecs.TYPE_FLOAT, null]
    ],
    comps_track = [["hud_marker__type", ecs.TYPE_STRING]]
  }
)

return {
  user_points
}