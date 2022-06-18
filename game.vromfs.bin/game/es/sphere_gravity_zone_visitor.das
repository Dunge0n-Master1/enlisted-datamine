require ecs
require GamePhys

def get_closest_zone_in_pos(position : float3)
  var closestZone = INVALID_ENTITY_ID // zone we are closest to which we are in radius of
  var closestZoneDistSq = -1.0
  query() <| $ [es(REQUIRE=zone__gravity)] (eid : EntityId; transform : float3x4; sphere_zone__radius : float)
    let zoneDistSq = length_sq(transform[3] - position)
    if zoneDistSq < sphere_zone__radius * sphere_zone__radius
      if closestZoneDistSq > zoneDistSq || closestZoneDistSq < 0.0
        closestZoneDistSq = zoneDistSq
        closestZone = eid
  return closestZone

[es(tag=server, no_order, REQUIRE=enableGravityZones)]
def apply_sphere_zone_gravity(info : UpdateStageInfoAct)
  query() <| $ [es] (transform aka object_transform : float3x4;
                     var local_gravity : float&)
    let gravityZone = get_closest_zone_in_pos(object_transform[3])

    if gravityZone == INVALID_ENTITY_ID
      local_gravity = gravity()
      return

    query(gravityZone) <| $ [es] (zone__gravity : float)
      local_gravity = zone__gravity