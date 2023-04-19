module human_parachute_common shared
require ecs
require app
require Dacoll
require GamePhys
require math.base
require DagorMath

def get_parachute_altitude(pos : float3)
  let posXZ = pos.xz
  var altitude = pos.y - traceht_lmesh(posXZ)

  var waterHeight = 0.0
  if traceht_water(pos, waterHeight)
    let waterAltitude = pos.y - waterHeight
    altitude = min(altitude, waterAltitude)

  return altitude

def parachute_create_for_eid(eid : EntityId; parachute_template : string)
  return createEntity(parachute_template) <| $(init)
    init |> set("item__ownerEid", eid)
    init |> set("skeleton_attach__attached", true)
    init |> set("slot_attach__attachedTo", eid)
    init |> set("skeleton_attach__attachedTo", eid)

def parachute_update_phys(parachute_eid : EntityId; velocity : float3; dt : float)
  var updatedVelocity = velocity
  query(parachute_eid) <| $ [es] (parachute__maxFallSpeed : float;
                                  parachute__deployTime : float;
                                  parachute__deployedAtTime : float)

    if velocity.y < 0.0
      let currentVelocity = length(velocity)
      let wantedVelocityRatio = cvt(get_sync_time(), parachute__deployedAtTime, parachute__deployedAtTime + parachute__deployTime,
                                    0.0, 1.0)
      let wantedVelocity = currentVelocity + (parachute__maxFallSpeed - currentVelocity) * square(wantedVelocityRatio)
      // g = k*V^2 where V is desired max speed
      let k = safediv(gravity(), square(wantedVelocity))
      let ungravitatedVelocity = velocity + float3(0.0, gravity() * dt, 0.0)
      updatedVelocity = velocity - k * normalize(ungravitatedVelocity) * length_sq(ungravitatedVelocity) * dt
  return updatedVelocity
