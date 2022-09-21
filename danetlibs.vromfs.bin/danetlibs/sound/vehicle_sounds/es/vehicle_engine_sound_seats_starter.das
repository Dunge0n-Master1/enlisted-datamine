require ecs

[es(tag=sound, REQUIRE=vehicleEngineSoundSeatsStarter, after=(vehicle_phys_sound_state, ship_sound_state))]
def vehicle_engine_sound_seats_starter(info : UpdateStageInfoAct;
                                       vehicle_seats__seatEids : EidList;
                                       var vehicle_engine_sound__shouldStart : bool&)
  vehicle_engine_sound__shouldStart = false
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      if seat__ownerEid != INVALID_ENTITY_ID
        vehicle_engine_sound__shouldStart = true
