require ecs

[es(tag=server, on_appear)]
def init_vehicle_seat_smoke_screen_allowed(evt : Event; seat__vehicleEid : EntityId; seat__id : int; var seat__allowSmokeScreen : bool&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats[seat__id])
    if seat != null
      seat__allowSmokeScreen = get_bool(seat, "smokeScreen") ?? seat__allowSmokeScreen
