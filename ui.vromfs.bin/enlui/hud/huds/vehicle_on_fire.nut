import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {playerEvents} = require("%ui/hud/state/eventlog.nut")
let {CmdShowVehicleDamageEffectsHint} = require("dasevents")
let {DM_EFFECT_FIRE} = require("dm")

ecs.register_es("ui_vehicle_on_fire_hp_es", {
  [CmdShowVehicleDamageEffectsHint] = function(evt, _eid, _comp) {
    let effects = evt.effects
    if ((effects & (1 << DM_EFFECT_FIRE)) != 0)
      playerEvents.pushEvent({name = "PlayerVehicleOnFire", text = loc("PlayerVehicleOnFire"), ttl = 10}, ["name"])
  }
},
{comps_rq=["hero"]})

