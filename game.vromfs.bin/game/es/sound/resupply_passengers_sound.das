require ecs
require soundEvent
require enlisted.events_enlisted


[es(tag=sound, REQUIRE=hero)]
def resupply_passengers_sound_resupply_finished(evt : CmdResupplyPassengersFinished)
  query(evt.vehicle) <| $ [es] (resupply_passengers_sound__path : string)
    oneshot(resupply_passengers_sound__path)
