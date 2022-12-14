import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")
let {
  active_bombs_Set,
  active_bombs_GetWatched,
  active_bombs_UpdateEid,
  active_bombs_DestroyEid
} = mkWatchedSetAndStorage("active_bombs_")


ecs.register_es(
  "active_bombs_hud_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp) {
      if (comp["projectile__exploded"]) {
        active_bombs_DestroyEid(eid)
        return
      }
      if (!comp["projectile__stopped"])
        return
      active_bombs_UpdateEid(eid, {maxDistance = comp["hud_marker__max_distance"], bombOwnerEid = comp["ownerEid"]})
    }
    function onDestroy(_, eid, __) {
      active_bombs_DestroyEid(eid)
    }
  },
  {
    comps_ro = [
      ["ownerEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0]
    ]
    comps_track = [
      ["projectile__exploded", ecs.TYPE_BOOL],
      ["projectile__stopped", ecs.TYPE_BOOL]
    ]
    comps_rq = ["hud_bomb_marker"]
  }
)

return {
  active_bombs_Set, active_bombs_GetWatched
}