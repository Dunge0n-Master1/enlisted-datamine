import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { localPlayerEid, localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { TEAM_UNASSIGNED } = require("team")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let {user_points, user_pointsSetKeyVal, user_pointsDeleteKey} = mkFrameIncrementObservable({}, "user_points")

let user_points_by_type = {
  main_user_point = null
  enemy_user_point = null
  item_user_point = null
  enemy_vehicle_user_point = null
  enemy_building_user_point = null
}.map(@(_) mkFrameIncrementObservable({}))

let mkCustomIcon = memoize(@(ico) ico == "" ? null :Picture($"!ui/skin#{ico}.svg"))

ecs.register_es("user_points_ui_es",
  {[["onInit", "onChange"]] = function(eid, comp){
      if (comp.team != TEAM_UNASSIGNED && comp.team != localPlayerTeam.value)
        return
      let typ = comp["hud_marker__type"]
      if (typ not in user_points_by_type)
        return
      let target = comp["target"]
      let image = ecs.obsolete_dbg_get_comp_val(target, "building_menu__image", "building_wall")
      let userPointOwner = comp["userPointOwner"]
      let res = {
        byLocalPlayer = userPointOwner == localPlayerEid.value && userPointOwner != ecs.INVALID_ENTITY_ID
        image,
        type = typ
        visible_distance = comp["hud_marker__visible_distance"]
        customIcon = mkCustomIcon(comp["userPointCustomIcon"])
      }
      user_pointsSetKeyVal(eid, res)
      user_points_by_type[typ].setKeyVal(eid, res)
    },
    function onDestroy(_, eid, comp){
      user_pointsDeleteKey(eid)
      user_points_by_type?[comp["hud_marker__type"]].deleteKey(eid)
    }
  },
  {
    comps_ro = [
      ["userPointOwner", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["userPointCustomIcon", ecs.TYPE_STRING, ""],
      ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["target", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["hud_marker__visible_distance", ecs.TYPE_FLOAT, null]
    ],
    comps_track = [["hud_marker__type", ecs.TYPE_STRING]]
  }
)

return {
  user_points_by_type = user_points_by_type.map(@(v) v.state)
  user_points
}