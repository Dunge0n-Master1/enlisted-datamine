require ecs
require vehicle
require DngPhysObj
require PhysObj
require Ship
require DngShip
require DngActor

[es(on_event=EventOnPartDamaged, tag=server)]
def wake_up_vehicle_on_part_damaged(evt : Event;
                                    var vehicle_net_phys : VehiclePhysActor)
  vehicle_net_phys.phys |> wakeUp()

[es(on_event=EventOnPartDamaged, tag=server)]
def wake_up_ship_on_part_damaged(evt : Event;
                                 var ship_net_phys : ShipActor)
  ship_net_phys.phys |> ship_phys_wake_up()

[es(on_event=EventOnPartDamaged, tag=server)]
def wake_up_phys_obj_on_part_damaged(evt : Event;
                                     var phys_obj_net_phys : PhysObjActor)
  phys_obj_net_phys.phys |> wakeUp()
