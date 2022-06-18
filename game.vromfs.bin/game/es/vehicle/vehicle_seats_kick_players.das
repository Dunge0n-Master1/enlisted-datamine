require ecs
require game.es.vehicle.vehicle_events

[es(no_order, tag=server, REQUIRE_NOT=ai_aircraft)]
def vehicle_seats_kick_players_es(info : UpdateStageInfoAct; eid : EntityId; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat__playerEid : EntityId = INVALID_ENTITY_ID)
      if seat__ownerEid != INVALID_ENTITY_ID && (!doesEntityExist(seat__ownerEid) || seat__playerEid == INVALID_ENTITY_ID)
        sendEvent(eid, [[CmdKickFromVehicle eid=seat__ownerEid]])
