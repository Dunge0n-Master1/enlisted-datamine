import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {lookAtVehicle, lookAtShip, lookAtPushableObject} = require("%ui/hud/state/actions_state.nut")
let {isDowned} = require("%ui/hud/state/health_state.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let isMachinegunner = require("%ui/hud/state/machinegunner_state.nut")
let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")

let canPush = Watched(false)

let showPushObjectTip = Computed(@() showPlayerHuds.value && !isMachinegunner.value && !inVehicle.value
                                  && !isDowned.value && (lookAtVehicle.value || lookAtShip.value)
                                  && lookAtPushableObject.value && canPush.value)

ecs.register_es("push_object_track_can_push_ui",
  {
    [["onInit", "onChange"]] = @(_, comp) canPush(comp.push_object__canPush),
    onDestroy = @() canPush(false)
  },
  {
    comps_rq=["watchedByPlr"]
    comps_track=[["push_object__canPush", ecs.TYPE_BOOL]]
  }
)

return { showPushObjectTip }
