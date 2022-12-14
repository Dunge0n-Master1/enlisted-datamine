import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { anyItemComps, mkItemDescFromComp } = require("items.nut")

let isBinocularMode = Watched(false)
let binocularInfo = Watched()
let heroBinocularEid = Watched(ecs.INVALID_ENTITY_ID)
let hasHeroBinocular = Computed(@() heroBinocularEid.value!=ecs.INVALID_ENTITY_ID)

let memoizedBinocularDescription = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 1)

ecs.register_es("binocular_hero_state", {
  onInit = function(_, eid, comp) {
    heroBinocularEid(eid)
    binocularInfo(memoizedBinocularDescription(comp["item__name"], 1, comp))
  }
  onDestroy = function(...) {
    heroBinocularEid(ecs.INVALID_ENTITY_ID)
    binocularInfo(null)
  }
},
{
  comps_rq = ["binocular", "watchedPlayerItem"]
  comps_ro = anyItemComps.comps_ro
})

ecs.register_es("binocular_mode_hero_state", {
  [["onInit", "onChange"]] = @(_, comp) isBinocularMode(comp["human_binocular__mode"])
  onDestroy = @(...) isBinocularMode(false)
},
{
  comps_track=[["human_binocular__mode", ecs.TYPE_BOOL]],
  comps_rq=[["watchedByPlr", ecs.TYPE_EID]]
})

return { hasHeroBinocular, isBinocularMode, heroBinocularEid, binocularInfo }