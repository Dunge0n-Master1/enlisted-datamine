import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  fortificationPreviewForwardArrowsSet,
  fortificationPreviewForwardArrowsGetWatched,
  fortificationPreviewForwardArrowsUpdateEid,
  fortificationPreviewForwardArrowsDestroyEid
} = mkWatchedSetAndStorage("fortificationPreviewForwardArrows")


ecs.register_es(
  "fortification_preview_forward_marker_hud_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp){
      if (comp["semi_transparent__visible"] == true) {
        fortificationPreviewForwardArrowsUpdateEid(eid, comp["additionalYawRotation"])
      }
      else
        fortificationPreviewForwardArrowsDestroyEid(eid)
    }
    onDestroy = function(_, eid, _comp) {
      fortificationPreviewForwardArrowsDestroyEid(eid)
    }
  },
  {
    comps_track = [
      ["additionalYawRotation", ecs.TYPE_FLOAT],
      ["semi_transparent__visible", ecs.TYPE_BOOL]
    ]
    comps_rq = ["builder_preview", "showForwardDirectionArrow"]
    comps_no = ["builder_server_preview"]
  }
)

return {
  fortificationPreviewForwardArrowsSet
  fortificationPreviewForwardArrowsGetWatched
}