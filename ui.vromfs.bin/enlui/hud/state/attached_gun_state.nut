import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isAttachedToGun = mkWatched(persist, "isAttachedToGun", false)

ecs.register_es("attached_gun_track_es",
  {
    [["onInit","onChange","onDestroy"]] = function(_eid,comp) {
      isAttachedToGun(comp["human_attached_gun__attachedGunEid"] != INVALID_ENTITY_ID)
    }
  },
  {
    comps_track = [["human_attached_gun__attachedGunEid", ecs.TYPE_EID]]
    comps_rq = ["hero"]
  }
)

return {
  isAttachedToGun
}
