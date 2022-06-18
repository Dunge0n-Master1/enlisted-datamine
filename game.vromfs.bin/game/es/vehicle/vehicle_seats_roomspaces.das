require ecs
require ecs.common

[es(tag=server, on_appear)]
def init_seat_roomspace(evt : Event; seat__id : int; seat__vehicleEid : EntityId; var seat__roomSpace : int&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    seat__roomSpace = get_int(*seat, "roomSpace") ?? -1
