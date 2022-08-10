import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  destroyable_ri_Set,
  destroyable_ri_GetWatched,
  destroyable_ri_UpdateEid,
  destroyable_ri_DestroyEid
} = mkWatchedSetAndStorage("destroyable_ri_")

ecs.register_es(
  "destroyable_ri_markers_es",
  {
    [["onInit", "onChange"]] = function(_evt, eid, comp){
      let addScoreTeam = comp["destroyable_ri__addScoreTeam"]
      destroyable_ri_UpdateEid(eid, addScoreTeam)
    }
    onDestroy = @(_evt, eid, _comp) destroyable_ri_DestroyEid(eid)
  },
  {
    comps_track = [
      ["destroyable_ri__addScoreTeam", ecs.TYPE_INT]
    ]
  }
)

return{
  destroyable_ri_Set,
  destroyable_ri_GetWatched
}