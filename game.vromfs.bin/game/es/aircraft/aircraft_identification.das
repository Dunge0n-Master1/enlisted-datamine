require ecs
require DagorMath
require EnlistedNet
require math.base
require enlisted.events_enlisted

[es(tag=gameClient, REQUIRE=watchedByPlr)]
def aircraft_identification(info : ParallelUpdateFrameDelayed;
                            var aircraft_identification__nextCheckAtTime : float&;
                            aircraft_identification__checkInterval : float;
                            transform aka hero_transform : float3x4;
                            camera__lookDir : float3;
                            aircraft_identification__detectDistance : float;
                            aircraft_identification__identifyDistance : float;
                            aircraft_identification__peripheryDistMult : float;
                            aircraft_identification__peripheryHalfAngleDeg : float;
                            aircraft_identification__focusHalfAngleDeg : float;
                            entity_mods__aircraftDetectAndIdentifyRangeMult : float = 1.0;
                            entity_mods__aircraftPeripheryAngleMult : float = 1.0)
  if info.curTime < aircraft_identification__nextCheckAtTime
    return
  aircraft_identification__nextCheckAtTime = info.curTime + aircraft_identification__checkInterval

  let lookDir = normalize(camera__lookDir)
  let focusedIdentifyDist = aircraft_identification__identifyDistance * entity_mods__aircraftDetectAndIdentifyRangeMult
  let peripheryIdentifyDist = focusedIdentifyDist * aircraft_identification__peripheryDistMult
  let focusedDetectDist = aircraft_identification__detectDistance * entity_mods__aircraftDetectAndIdentifyRangeMult
  let peripheryDetectDist = focusedDetectDist * aircraft_identification__peripheryDistMult
  let focusAngleCos = cos(clamp(deg_to_rad(aircraft_identification__focusHalfAngleDeg * entity_mods__aircraftPeripheryAngleMult), 0.0, PI))
  let peripheryAngleCos = cos(clamp(deg_to_rad(aircraft_identification__peripheryHalfAngleDeg * entity_mods__aircraftPeripheryAngleMult), 0.0, PI))

  query() <| $ [es(REQUIRE=airplane, REQUIRE_NOT=ai_aircraft)] (eid : EntityId;
                                                                transform : float3x4;
                                                                var hud_aircraft_marker__isIdentified : bool&;
                                                                var hud_aircraft_marker__isVisible : bool&)
    var dirToAirplane = transform[3] - hero_transform[3]
    let distance = length(dirToAirplane)
    dirToAirplane *= safeinv(distance)
    let dirDot = dot(lookDir, dirToAirplane)
    let isOnPeriphery = dirDot < focusAngleCos
    let isInVision = dirDot > peripheryAngleCos
    let identifyDist = isOnPeriphery ? peripheryIdentifyDist : focusedIdentifyDist
    let detectDist = isOnPeriphery ? peripheryDetectDist : focusedDetectDist

    hud_aircraft_marker__isVisible = has(eid, "heroVehicle") ? false : (isInVision && distance < detectDist)
    hud_aircraft_marker__isIdentified = hud_aircraft_marker__isVisible && distance < identifyDist

[es(tag=gameClient, no_order, REQUIRE=ai_aircraft)]
def hidden_ai_aircraft_identification(info : ParallelUpdateFrameDelayed;
                                      transform : float3x4;
                                      var hud_aircraft_marker__isVisible : bool&)
  // If hidden, aircraft is at -500 height (get_hidden_pos().y)
  // The catch is that it may be slightly extrapolated from the server-side position
  // That's why there is a 10 meter allowance
  hud_aircraft_marker__isVisible = transform[3].y > (get_hidden_pos().y + 10.f)

[es(tag=gameClient, after=aircraft_identification, REQUIRE_NOT=ai_aircraft)]
def hidden_aircraft_identification(info : ParallelUpdateFrameDelayed;
                                   transform : float3x4;
                                   var hud_aircraft_marker__isVisible : bool&)
  if transform[3].y < (get_hidden_pos().y + 10.f)
    hud_aircraft_marker__isVisible = false
