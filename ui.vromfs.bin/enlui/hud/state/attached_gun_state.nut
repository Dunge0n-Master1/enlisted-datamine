import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isAttachedToGun = Watched(false)

ecs.register_es("attached_gun_track_es",
  {
    [["onInit","onChange"]] = function(_eid,comp) {
      isAttachedToGun(comp["human_attached_gun__attachedGunEid"] != ecs.INVALID_ENTITY_ID)
    }
    onDestroy = @(...) isAttachedToGun(false)
  },
  {
    comps_track = [["human_attached_gun__attachedGunEid", ecs.TYPE_EID]]
    comps_rq = ["hero"]
  }
)

return {
  isAttachedToGun
}
