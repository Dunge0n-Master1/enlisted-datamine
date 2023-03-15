require ecs
require DagorMath
require GamePhys
require math.base
require enlisted.events_enlisted

[es(tag=gameClient, on_appear, REQUIRE=plane_wreckage)]
def wreckage_phys_init_es(evt : Event;
                          plane_wreckage__mass : float;
                          plane_wreckage__startImpulse : float3;
                          plane_wreckage__startMoment : float3;
                          plane_wreckage__tm : float3x4;
                          var plane_wreckage__vel : float3&;
                          var plane_wreckage__omega : float3&)
  let invMass = 1.0 / plane_wreckage__mass
  plane_wreckage__vel = plane_wreckage__vel + plane_wreckage__startImpulse * invMass
  plane_wreckage__omega = rotate(plane_wreckage__tm, (plane_wreckage__omega + plane_wreckage__startMoment * invMass))

[es(tag=gameClient, REQUIRE=plane_wreckage, no_order)]
def wreckage_phys_es(info : ParallelUpdateFrameDelayed;
                     eid : ecs::EntityId;
                     plane_wreckage__offset : float3;
                     plane_wreckage__mass : float;
                     var transform : float3x4;
                     var plane_wreckage__ttl : float&;
                     var plane_wreckage__pos : float3&;
                     var plane_wreckage__orient : float4&;
                     var plane_wreckage__vel : float3&;
                     plane_wreckage__omega : float3)
  let dt = info.dt

  plane_wreckage__ttl -= dt
  if plane_wreckage__ttl <= 0.f
    destroyEntity(eid)
    return

  let invMass = 1.0 / plane_wreckage__mass
  let mass = plane_wreckage__mass

  let acc = invMass * float3(0.0, -gravity() * mass, 0.0)
  plane_wreckage__vel += acc * dt

  plane_wreckage__pos = plane_wreckage__pos + plane_wreckage__vel * dt

  let orientInc = plane_wreckage__omega * dt
  let quatInc   = quat(orientInc, length(orientInc))
  plane_wreckage__orient = float4(normalize(quat(plane_wreckage__orient) * quatInc))

  var offsetTm = IDENT_TM
  offsetTm[3] = plane_wreckage__offset

  var wreckageTm : float3x4
  make_tm(quat(plane_wreckage__orient), plane_wreckage__pos, wreckageTm)
  transform = wreckageTm * offsetTm
