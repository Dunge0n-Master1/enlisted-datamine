require ecs
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common

[es(tag=server, REQUIRE=nonLethalExplodeOnFire, track=fire_damage__isBurn, on_appear)]
def non_lethal_explode_on_fire(evt : Event;
                               eid : EntityId;
                               fire_damage__isBurn : bool;
                               isExploded : bool;
                               isAlive : bool;
                               vehicle_seats__seatEids : EidList)
  kick_all_from_vehicle(eid, vehicle_seats__seatEids)
  if fire_damage__isBurn && !isExploded && isAlive
    sendEvent(eid, [[CmdExplosionFatal offender=INVALID_ENTITY_ID, gunPropsId=-1, shellId=-1]])