require ecs

require game.es.turrets_common

def set_gun_owner_impl(turret_eids, seat_eids)
  for turretNo, turretEid in iter_range(turret_eids), turret_eids
    let gunOwner = find_gun_owner(turretNo, seat_eids)
    setOptional(turretEid, "gun__owner", gunOwner.eid)
    setOptional(turretEid, "turret__isControlledByAi", !!gunOwner.eid && !gunOwner.isPlayer)

[es(on_event=(EventOnGunCreated, EventOnSeatOwnersChanged), REQUIRE=vehicle, REQUIRE_NOT=ai_aircraft)]
def turret_gun_owners_on_change(evt : Event; turret_control__gunEids, vehicle_seats__seatEids : EidList)
  set_gun_owner_impl(turret_control__gunEids, vehicle_seats__seatEids)

[es(track=seat__ownerControls, REQUIRE=seat__ownerControls)]
def vehicle_seats_player_controls_on_change(evt : Event; seat__vehicleEid : EntityId)
  query(seat__vehicleEid) <| $ [es(REQUIRE=vehicle, REQUIRE_NOT=ai_aircraft)] (turret_control__gunEids, vehicle_seats__seatEids : EidList)
    set_gun_owner_impl(turret_control__gunEids, vehicle_seats__seatEids)