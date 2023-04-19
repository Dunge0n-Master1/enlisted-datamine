import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")
let {
  simple_map_markers_Set,
  simple_map_markers_GetWatched,
  simple_map_markers_UpdateEid,
  simple_map_markers_DestroyEid
} = mkWatchedSetAndStorage("simple_map_markers_")

ecs.register_es(
  "simple_map_markers_ui_state",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      if (comp.map_icon__isActive)
        simple_map_markers_UpdateEid(eid, {
          image = comp.map_icon__image
          visibleToSquad = comp.map_icon__visibleToSquad
        })
      else
        simple_map_markers_DestroyEid(eid)
    }
    onDestroy = @(eid, _comp) simple_map_markers_DestroyEid(eid)
  },
  {
    comps_track = [["map_icon__isActive", ecs.TYPE_BOOL, true]]
    comps_ro = [
      ["map_icon__image", ecs.TYPE_STRING],
      ["map_icon__visibleToSquad", ecs.TYPE_EID, null],
    ],
  }
)

return{
  simple_map_markers_Set
  simple_map_markers_GetWatched
}