require ecs
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require math.base
require DagorMath

def is_in_zone(pos : float3; itm : float3x4)
  return IDENT_BBOX & (itm * pos)

def cleanun_respawn(zone_inv_tm : float3x4; ignore_eid : EntityId)
  query() <| $ [es] (eid : EntityId;
                     transform : float3x4;
                     lastOffender : EntityId;
                     vehicle_seats__seatEids : EidList;
                     ownedBySquad : EntityId = INVALID_ENTITY_ID)
    if !!ownedBySquad && !(get_bool(ownedBySquad, "squad__hasMembersBefore") ?? false)
      return
    if eid != ignore_eid && is_in_zone(transform[3], zone_inv_tm) && !is_vehicle_with_alive_crew(vehicle_seats__seatEids)
      sendEvent(eid, [[CmdKillVehicle offender=lastOffender]])

[es(tag=server, on_appear, REQUIRE=(plane_carrier_assist__isOnCarrier, ownedBySquad))]
def cleanup_carrier_on_vehicle_spawn(evt : Event; eid : EntityId; transform aka vehicle_transform : float3x4)
  let vehiclePos = vehicle_transform[3]
  find_query() <| $ [es(REQUIRE=aircraftCarrierLandingZone)] (inverseTransform : float3x4)
    if is_in_zone(vehiclePos, inverseTransform)
      cleanun_respawn(inverseTransform, eid)
      return true
    return false
