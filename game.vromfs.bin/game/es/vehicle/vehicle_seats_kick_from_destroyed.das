require ecs
require vehicle
require game.es.vehicle.vehicle_events

[es(tag=server, on_disappear)]
def vehicle_seats_kick_from_destroyed(evt : Event;
                                      eid : EntityId;
                                      vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    sendEventImmediate(eid, [[CmdKickFromVehicle eid=ownerEid]])
