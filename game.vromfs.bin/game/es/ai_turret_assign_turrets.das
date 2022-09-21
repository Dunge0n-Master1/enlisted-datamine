require ecs
require math.base
require DagorMath

[es(tag=server, on_appear, REQUIRE=zone_assignAiTurretsTeam)]
def assign_ai_turrets_team_zone_created(evt : Event;
                                        transform : float3x4;
                                        sphere_zone__radius : float;
                                        team aka assign_team : int)
  let zonePos = transform[3]
  let zoneRadiusSq = square(sphere_zone__radius)
  query() <| $ [es(REQUIRE=ai_gunners__assignTeam)] (transform aka turret_transform : float3x4;
                                                     var team : int&)
    if distance_sq(turret_transform[3], zonePos) < zoneRadiusSq
      team = assign_team

[es(tag=server, on_appear, REQUIRE=ai_gunners__assignTeam)]
def assign_ai_turrets_team_turret_created(evt : Event;
                                          transform aka turret_transform : float3x4;
                                          var team aka turret_team : int&)
  let turretPos = turret_transform[3]
  find_query() <| $ [es(REQUIRE=zone_assignAiTurretsTeam)] (transform aka zone_transform : float3x4;
                                                            sphere_zone__radius : float;
                                                            team aka assign_team : int)
    let zonePos = zone_transform[3]
    let zoneRadiusSq = square(sphere_zone__radius)
    if distance_sq(turretPos, zonePos) < zoneRadiusSq
      turret_team = assign_team
      return true
    return false
