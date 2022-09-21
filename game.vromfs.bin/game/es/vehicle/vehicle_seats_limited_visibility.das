require ecs
require vehicle
require game.es.vehicle.vehicle_events


def seat_limited_visibility_impl(seat__ownerEid, seat__limitedVisibility)
  if !seat__ownerEid
    return

  let isHidden = get_bool(seat__ownerEid, "isInVehicleHidden") ?? false
  let isVisionLimited = seat__limitedVisibility > 0
  setOptional(seat__ownerEid, "isBlinded", isHidden && isVisionLimited)

[es(tag=server, on_event=EventOnSeatOwnersChanged)]
def seat_visibility_changed(evt : Event; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__limitedVisibility : int)
      seat_limited_visibility_impl(seat__ownerEid, seat__limitedVisibility)

[es(tag=server, track=seat__limitedVisibility)]
def seat_limited_visibility_changed(evt : Event; seat__ownerEid : EntityId; seat__limitedVisibility : int)
  seat_limited_visibility_impl(seat__ownerEid, seat__limitedVisibility)

[es(tag=server, track=isInVehicle)]
def seats_visibility_enter(evt : Event;
                           isInVehicle : bool;
                           var isBlinded : bool&)
  if !isInVehicle
    isBlinded = false;
