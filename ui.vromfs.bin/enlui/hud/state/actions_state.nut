import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let defValue = freeze({
  useActionEid = ecs.INVALID_ENTITY_ID
  useActionAvailable = false
  lookAtEid = ecs.INVALID_ENTITY_ID
  lookAtVehicle = false
  lookAtShip = false
  lookAtPushableObject = false
  pickupItemEid = ecs.INVALID_ENTITY_ID
  pickupItemName = null
  customUsePrompt = null
})

let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")

let exportState = watchedTable2TableOfWatched(state)

let vehicleQuery = ecs.SqQuery("vehicleQuery", {
  comps_ro=[
    ["vehicle", ecs.TYPE_TAG, null],
    ["ship", ecs.TYPE_TAG, null],
    ["push_object__energyScale", ecs.TYPE_FLOAT, -1.0],
  ]
})

ecs.register_es("hero_state_hud_state_ui_es", {
  [["onInit", "onChange"]] = function(_eid,comp) {
    local newState = {
      useActionEid = comp.useActionEid
      useActionAvailable = comp.useActionAvailable
      lookAtEid = comp.lookAtEid
      lookAtVehicle = false
      lookAtShip = false
      lookAtPushableObject = false
      pickupItemEid = comp.pickupItemEid
      pickupItemName = comp.pickupItemName
      customUsePrompt = comp.customUsePrompt
    }

    vehicleQuery(comp.useActionEid, function(_, comp) {
      newState.lookAtVehicle = comp.vehicle != null
      newState.lookAtShip = comp.ship != null
      newState.lookAtPushableObject = comp.push_object__energyScale > 0.0
    })

    stateSetValue(newState)
  }
  function onDestroy() {
    stateSetValue(defValue)
  }
}, {
  comps_rq = ["watchedByPlr"]
  comps_track = [
    ["useActionEid", ecs.TYPE_EID],
    ["useActionAvailable", ecs.TYPE_INT],
    ["lookAtEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["pickupItemEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["pickupItemName", ecs.TYPE_STRING, null],
    ["customUsePrompt", ecs.TYPE_STRING, null],
  ]
})

return exportState
