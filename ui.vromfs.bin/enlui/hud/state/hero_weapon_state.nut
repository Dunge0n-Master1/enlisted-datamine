import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let currentGunEid = Watched(INVALID_ENTITY_ID)

ecs.register_es("watched_player_current_gun_eid_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    currentGunEid(comp.human_weap__currentGunEid)
  }
},
{ comps_track=[["human_weap__currentGunEid", ecs.TYPE_EID]] comps_rq = ["watchedByPlr"] })

return {
  currentGunEid
}