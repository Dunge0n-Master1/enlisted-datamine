import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let hasHeroFlask = Watched(false)
let flaskAffectApplied = Watched(false)

ecs.register_es("flask_hero_state", {
  [["onInit", "onChange"]] = @(_evt, _eid, comp) hasHeroFlask(comp.hasFlask)
  onDestroy = @(...) hasHeroFlask(false)
},
{
  comps_track=[["hasFlask", ecs.TYPE_BOOL]],
  comps_rq=["hero"]
})

ecs.register_es("has_hero_flask_affect", {
  [["onInit", "onChange"]] = @(_evt, _eid, comp) flaskAffectApplied(comp.flask__affectEid != INVALID_ENTITY_ID)
  onDestroy = @(...) flaskAffectApplied(false)
},
{
  comps_track=[["flask__affectEid", ecs.TYPE_EID]],
  comps_rq=["hero"]
})

return {
  hasHeroFlask
  flaskAffectApplied
}
