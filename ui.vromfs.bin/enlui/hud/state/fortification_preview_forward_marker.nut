import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let fortificationPreviewForwardArrows = Watched({})

let function trackComponents(eid, comp) {
  if (comp["semi_transparent__visible"] == true) {
    fortificationPreviewForwardArrows.mutate(@(v) v[eid] <- comp["additionalYawRotation"])
  }
  else if (fortificationPreviewForwardArrows.value?[eid] != null) {
    fortificationPreviewForwardArrows.mutate(@(v) delete v[eid])
  }
}

ecs.register_es(
  "fortification_preview_forward_marker_hud_es",
  {
    onInit = trackComponents
    onChange = trackComponents
    onDestroy = function(eid, _comp) {
      if (fortificationPreviewForwardArrows.value?[eid] != null) {
        fortificationPreviewForwardArrows.mutate(@(v) delete v[eid])
      }
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
  fortificationPreviewForwardArrows
}