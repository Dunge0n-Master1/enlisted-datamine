import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let fortificationPreviewCanBeRotated = Watched(false)

let trackComponents = @(_eid, comp) fortificationPreviewCanBeRotated(comp["semi_transparent__visible"] == true)

ecs.register_es(
  "fortification_preview_can_be_rotated_hud_es",
  {
    onInit = trackComponents
    onChange = trackComponents
    onDestroy = @(_eid, _comp) fortificationPreviewCanBeRotated(false)
  },
  {
    comps_track = [
      ["additionalYawRotation", ecs.TYPE_FLOAT],
      ["semi_transparent__visible", ecs.TYPE_BOOL]
    ]
    comps_rq = ["builder_preview"]
    comps_no = ["builder_server_preview"]
  }
)

return {
  fortificationPreviewCanBeRotated
}