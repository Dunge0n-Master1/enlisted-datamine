import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let defValue = freeze({
  useActionEid = INVALID_ENTITY_ID
  useActionAvailable = false
  lookAtEid = INVALID_ENTITY_ID
  lookAtVehicle = false
  pickupItemEid = INVALID_ENTITY_ID
  pickupItemName = null
  customUsePrompt = null
})

let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")

let {exportState} = watchedTable2TableOfWatched({state, defValue, plainOut=false})

ecs.register_es("hero_state_hud_state_ui_es", {
  [["onInit", "onChange"]] = function(_eid,comp) {
    stateSetValue({
      useActionEid = comp.useActionEid
      useActionAvailable = comp.useActionAvailable
      lookAtEid = comp.lookAtEid
      lookAtVehicle = ecs.obsolete_dbg_get_comp_val(comp.useActionEid, "vehicle") != null
      pickupItemEid = comp.pickupItemEid
      pickupItemName = comp.pickupItemName
      customUsePrompt = comp.customUsePrompt
    })
  }
  function onDestroy() {
    stateSetValue(defValue)
  }
}, {
  comps_rq = ["watchedByPlr"]
  comps_track = [
    ["useActionEid", ecs.TYPE_EID],
    ["useActionAvailable", ecs.TYPE_INT],
    ["lookAtEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["pickupItemEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["pickupItemName", ecs.TYPE_STRING, null],
    ["customUsePrompt", ecs.TYPE_STRING, null],
  ]
})

return exportState
