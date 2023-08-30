require ecs
require soundEvent


[es(tag=sound, track=resupplyStarted, REQUIRE=vehicleWithWatched)]
def vehicle_resupply_sound_resupply_started(evt : Event; resupplyStarted : bool; resupply_vehicle_sound__resupplyStartedPath : string; transform : float3x4)
  if resupplyStarted
    oneshot(resupply_vehicle_sound__resupplyStartedPath, transform[3])


[es(tag=sound, on_event=CmdResupplyVehicle, REQUIRE=vehicleWithWatched)]
def vehicle_resupply_sound_on_resupply(evt : Event; resupply_vehicle_sound__resupplyPath : string; transform : float3x4)
  oneshot(resupply_vehicle_sound__resupplyPath, transform[3])
