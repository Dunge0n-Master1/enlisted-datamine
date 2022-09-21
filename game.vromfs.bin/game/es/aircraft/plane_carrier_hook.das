require ecs
require math.base
require DagorMath
require Plane
require EnlistedPlane
require GamePhys
require game.es.events

[es(on_appear)]
def init_inverse_transform(evt : Event; transform : float3x4; var inverseTransform : float3x4)
  inverseTransform = inverse(transform)

[es]
def plane_hook_reset_at_height(evt : CmdPostPhysUpdate;
                               plane_net_phys : PlaneActor;
                               plane_landing__hookReactivateAtHeight : float;
                               var plane_landing__hookActive : bool&)
  plane_landing__hookActive ||= !plane_net_phys.phys.Gears.onSurface && plane_net_phys.phys.currentAlt > plane_landing__hookReactivateAtHeight

[es(on_appear)]
def plane_init_carrier_runway(evt : Event;
                              transform : float3x4;
                              var carrier__runwayStart : float3&;
                              var carrier__runwayEnd : float3&;
                              var carrier__runwayDir : float3&)
  let runwayAxisId = length_sq(transform[0]) > length_sq(transform[2]) ? 0 : 2
  carrier__runwayStart = transform[3] - transform[runwayAxisId] * 0.5
  carrier__runwayEnd = transform[3] + transform[runwayAxisId] * 0.5
  carrier__runwayDir = normalize(transform[runwayAxisId])

[es]
def plane_hook_phys_update(evt : CmdPostPhysUpdate;
                           plane_landing__hookPosLocal : float3;
                           plane_landing__hookHeight : float;
                           plane_landing__hookReleaseSpeedSq : float;
                           var plane_landing__hookActive : bool&;
                           var plane_net_phys : PlaneActor&)
  if !plane_landing__hookActive
    return
  find_query() <| $ [es(REQUIRE=aircraftCarrierLandingZone)] (carrier_cable__minAcceleration : float;
                                                              carrier_cable__maxAcceleration : float;
                                                              carrier__runwayStart : float3;
                                                              carrier__runwayEnd : float3;
                                                              carrier__runwayDir : float3;
                                                              inverseTransform : float3x4)
    assume fm = plane_net_phys.phys

    if fm.currentAlt > plane_landing__hookHeight
      return false

    var planeCurrentTm : float3x4
    fm.currentState.location |> location_toTM(planeCurrentTm)
    let planePos = planeCurrentTm[3]
    let planeDir = planeCurrentTm[0]

    let isInZone = IDENT_BBOX & (inverseTransform * planePos)
    if !isInZone
      return false

    let relativeVelocity = float3(fm.currentState.velocity) // TODO: we dont have moving carriers yet
    let isAlignedWithRunway = dot(carrier__runwayDir, relativeVelocity) >= 0.
    let lineEndPos = isAlignedWithRunway ? carrier__runwayEnd : carrier__runwayStart

    let hookPos = planeCurrentTm * plane_landing__hookPosLocal
    let forceDir = normalize((isAlignedWithRunway ? carrier__runwayStart : carrier__runwayEnd) - hookPos)

    if dot(planeDir, forceDir) < 0. // only pull backwards
      let maxDistanceLeft = max(1e-6, length(lineEndPos - planePos))
      let deceleration = clamp(0.5 * length_sq(relativeVelocity) / maxDistanceLeft, carrier_cable__minAcceleration, carrier_cable__maxAcceleration)
      let hookForce = deceleration * fm.M.mass
      let forceLocal = inverse(planeCurrentTm) * (forceDir * hookForce)
      fm |> flight_model_addForceImmediately(plane_landing__hookPosLocal, forceLocal)
      if length_sq(relativeVelocity.xz) < plane_landing__hookReleaseSpeedSq
        plane_landing__hookActive = false
    return true