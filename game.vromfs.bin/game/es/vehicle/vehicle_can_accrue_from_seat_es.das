require ecs
require ecs.common
require game.es.vehicle.vehicle_seats_common

[es(on_appear)]
def vehicle_accrue_from_seat_init_es(evt : Event;
                                     seat__id : int;
                                     seat__vehicleEid : EntityId;
                                     var seat__adjacentSeat : int&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat != null
      seat__adjacentSeat = find_seat_no(get_string(seat, "adjacentSeat", ""), vehicle_seats__seats)
