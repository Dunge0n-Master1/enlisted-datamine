require ecs
require game.es.vehicle.vehicle_events

[es(tag=server, on_disappear)]
def vehicle_seats_kick_not_exist(evt : Event; eid : EntityId; human_vehicle__occupiedSeatEid : EntityId)
  query(human_vehicle__occupiedSeatEid) <| $ [es] (seat__vehicleEid : EntityId; seat__ownerEid : EntityId)
    if seat__ownerEid == eid
      sendEvent(seat__vehicleEid, [[CmdKickFromVehicle eid=seat__ownerEid]])
