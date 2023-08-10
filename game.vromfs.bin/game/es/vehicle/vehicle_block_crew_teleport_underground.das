require ecs

[es(tag=server, on_appear, track=isInVehicle)]
def vehicle_block_crew_teleport_underground(evt : Event;
                                            isInVehicle : bool;
                                            var underground_teleporter__enabled : bool&)
  underground_teleporter__enabled = !isInVehicle
