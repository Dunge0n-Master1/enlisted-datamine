require ecs
require vehicle


[es(tag=server, no_order)]
def vehicle_phys_update_state(evt : UpdateStageInfoAct;
                              vehicle_net_phys : VehiclePhysActor;
                              var vehicle_net_phys__isEngineDestroyed : bool&)
  vehicle_net_phys__isEngineDestroyed = vehicle_net_phys.phys.engineReadyness < 0.01


[es(on_appear, on_event=EventOnSeatOwnersChanged, track=vehicle_net_phys__isEngineDestroyed)]
def vehicle_phys_update_engine_state(evt : Event;
                                     vehicle_seats__seatEids : EidList;
                                     vehicle_net_phys__isEngineDestroyed : bool;
                                     var vehicle_net_phys : VehiclePhysActor&)
  var hasCrew = false
  for seatEid in vehicle_seats__seatEids
    hasCrew ||= get_bool(seatEid, "seat__isOwnerAlive") ?? false
    if hasCrew
      break

  let isEngineWorking = hasCrew && !vehicle_net_phys__isEngineDestroyed
  vehicle_net_phys.phys.disableEngineOmega = !isEngineWorking
  vehicle_phys_setIsICEWorking(vehicle_net_phys.phys, isEngineWorking)
