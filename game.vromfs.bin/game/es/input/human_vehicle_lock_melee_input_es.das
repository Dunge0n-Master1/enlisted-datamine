require ecs

[es(tag=input, track=human_anim__vehicleSelected, on_appear, before=human_input_es)]
def human_lock_shoot_in_vehicle_es(evt : Event;
                                   eid : EntityId;
                                   human_anim__vehicleSelected : EntityId;
                                   var human_input__canShoot : bool&)
  human_input__canShoot = true
  if !human_anim__vehicleSelected
    return

  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
        if eid == seat__ownerEid && !has(seatEid, "seat_anim__fireReadyUpper")
          human_input__canShoot = false

[es(tag=input, track=seat__ownerEid, on_appear)]
def vehicle_lock_human_shoot_es(evt : Event; eid : EntityId; seat__ownerEid : EntityId)
  query(seat__ownerEid) <| $ [es(REQUIRE=hero)] (var human_input__canShoot : bool&)
    human_input__canShoot = has(eid, "seat_anim__fireReadyUpper")
