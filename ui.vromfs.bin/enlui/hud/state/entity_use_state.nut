import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {curTime} = require("%ui/hud/state/time_state.nut")
let {frameUpdateCounter} = require("%ui/scene_update.nut")
let {lerp} = require("%sqstd/math.nut")

let entityToUse = Watched(ecs.INVALID_ENTITY_ID)
let entityUseStart = Watched(-1)
let entityUseEnd = Watched(-1)
ecs.register_es("medkitUsage",{
  [["onInit","onChange"]] = function(_eid, comp){
    entityUseStart(comp["human_inventory__entityUseStart"])
    entityUseEnd(comp["human_inventory__entityUseEnd"])
    entityToUse(comp["human_inventory__entityToUse"])
  },
  onDestroy = @() entityUseEnd(-1.0) ?? entityUseStart(-1.0) ?? entityToUse(ecs.INVALID_ENTITY_ID)
}, {comps_track=[
    ["human_inventory__entityUseStart",ecs.TYPE_FLOAT],
    ["human_inventory__entityUseEnd",ecs.TYPE_FLOAT],
    ["human_inventory__entityToUse",ecs.TYPE_EID]
  ], comps_rq=["watchedByPlr"]})

let itemUseProgress = Watched(0)

let doCalcTime = Watched(false)
let function calcitemUseProgress(...){
  local res = 0
  if (curTime.value <= entityUseEnd.value) {
    res = lerp(entityUseStart.value, entityUseEnd.value, 0.0, 100.0, curTime.value)
    if (!doCalcTime.value)
      doCalcTime(true)
  }
  else
    doCalcTime(false)

  itemUseProgress(res)
}
doCalcTime.subscribe(function(v) {
  if (!v)
    frameUpdateCounter.unsubscribe(calcitemUseProgress)
  else
    frameUpdateCounter.subscribe(calcitemUseProgress)
})

entityUseEnd.subscribe(calcitemUseProgress)
entityUseStart.subscribe(calcitemUseProgress)


return {
  medkitStartTime = entityUseStart
  medkitEndTime = entityUseEnd
  entityToUse
  entityUseEnd
  entityUseStart
  itemUseProgress
}
