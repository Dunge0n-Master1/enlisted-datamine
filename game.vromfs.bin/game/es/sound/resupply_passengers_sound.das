require ecs
require soundEvent
require enlisted.events_enlisted


[es(tag=sound, REQUIRE=hero)]
def resupply_passengers_play_complete_sound(evt : CmdResupplyPassengersFinished)
  let sound = get_string(evt.vehicle, "resupply_vehicle__resupplyPassengersSound", "")
  if !empty(sound)
    oneshot(sound)
