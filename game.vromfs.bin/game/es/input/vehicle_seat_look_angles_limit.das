require ecs
require ecs.safe
require math.base


[es(tag=input, on_appear, after=create_vehicle_seats)]
def vehicle_seat_look_angle_limit_on_appear(evt : Event;
                                            vehicle_seats__seatEids : EidList;
                                            [[shared_comp]] vehicle_seats__seats : Array)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__id : int;
                              var seat__holdingGunPassengerVertLookLimit : float2&)
      let seat = vehicle_seats__seats?[seat__id] ?as Object
      seat__holdingGunPassengerVertLookLimit = seat?.holdingGunPassengerVertLookLimit ?? float2(-25.0, 90.0)
