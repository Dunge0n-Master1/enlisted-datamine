import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let hasHeroBinocular = Watched(false)
let isBinocularMode = Watched(false)

ecs.register_es("binocular_hero_state", {
  [["onInit", "onChange"]] = @(_, comp) hasHeroBinocular(comp["human_binocular__eid"] != INVALID_ENTITY_ID)
  onDestroy = @(...) hasHeroBinocular(false)
},
{
  comps_track=[["human_binocular__eid", ecs.TYPE_EID]],
  comps_rq=["hero"]
})

ecs.register_es("binocular_mode_hero_state", {
  [["onInit", "onChange"]] = @(_, comp) isBinocularMode(comp["human_binocular__mode"])
  onDestroy = @(...) isBinocularMode(false)
},
{
  comps_track=[["human_binocular__mode", ecs.TYPE_BOOL]],
  comps_rq=["hero"]
})

return { hasHeroBinocular, isBinocularMode }