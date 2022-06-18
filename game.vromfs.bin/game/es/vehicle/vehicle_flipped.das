require ecs
require Dacoll
require game.es.vehicle.vehicle_seats_common


[es(tag=server, no_order)]
def vehicle_check_flipped(act : UpdateStageInfoAct;
                          transform : float3x4;
                          vehicle_flipped__checkMinAngle : float;
                          vehicle_flipped__checkMinDistance : float;
                          vehicle_flipped__checkInterval : float;
                          var vehicle_flipped__nextCheckAt : float&;
                          var vehicle_flipped__isFlipped : bool&)
  if vehicle_flipped__nextCheckAt > act.curTime
    return
  vehicle_flipped__nextCheckAt = act.curTime + vehicle_flipped__checkInterval

  var flipped = false
  let vehicleUpDir = transform[1]
  if vehicleUpDir.y < vehicle_flipped__checkMinAngle
    let vehiclePos = transform[3]
    var norm : float3
    var t = vehicle_flipped__checkMinDistance
    flipped = traceray_normalized(vehiclePos, vehicleUpDir, t, norm)
  vehicle_flipped__isFlipped = flipped


[es(tag=server, track=vehicle_flipped__isFlipped, REQUIRE=kickPassengersOnFlip)]
def vehicle_kick_passengers_on_flip(evt : Event;
                                    eid : EntityId;
                                    vehicle_seats__seatEids : EidList;
                                    vehicle_flipped__isFlipped : bool)
  if !vehicle_flipped__isFlipped
    return

  kick_all_from_vehicle(eid, vehicle_seats__seatEids)