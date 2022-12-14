import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { anyItemComps, mkItemDescFromComp } = require("items.nut")
let heroFlaskEid = Watched(ecs.INVALID_ENTITY_ID)
let heroFlaskInfo = Watched()
let hasHeroFlask = Computed(@() heroFlaskEid.value!=ecs.INVALID_ENTITY_ID)
let flaskAffectApplied = Watched(false)
let memoizedDesc = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 1)

ecs.register_es("flask_hero_state", {
  onInit = function(_, eid, comp) {
    heroFlaskEid(eid)
    heroFlaskInfo(memoizedDesc(comp["item__name"], eid, comp))
  }
  onDestroy = function(...) {
    heroFlaskEid(ecs.INVALID_ENTITY_ID)
    heroFlaskInfo(null)
  }
},
{
  comps_rq=["flask","watchedPlayerItem"]
  comps_ro = anyItemComps.comps_ro
})

ecs.register_es("has_hero_flask_affect", {
  [["onInit", "onChange"]] = @(_evt, _eid, comp) flaskAffectApplied(comp.flask__affectEid != ecs.INVALID_ENTITY_ID)
  onDestroy = @(...) flaskAffectApplied(false)
},
{
  comps_track=[["flask__affectEid", ecs.TYPE_EID]],
  comps_rq=[["watchedByPlr", ecs.TYPE_EID]]
})

return {
  hasHeroFlask
  heroFlaskEid
  flaskAffectApplied
  heroFlaskInfo
}
