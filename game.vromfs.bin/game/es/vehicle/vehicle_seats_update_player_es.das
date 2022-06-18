require ecs

[es(tag=server)]
def vehicle_seats_update_player_es(info : UpdateStageInfoAct; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; var seat__isPlayer : bool&)
      query(seat__ownerEid) <| $ [es] (possessedByPlr : EntityId = INVALID_ENTITY_ID)
        seat__isPlayer = possessedByPlr != INVALID_ENTITY_ID
