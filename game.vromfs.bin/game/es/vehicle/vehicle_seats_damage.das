require ecs
require vehicle
require math
require math.base
require game.es.events

[es(after=after_net_phys_sync, before=vehicle_acceleration_es)]
def vehicle_seats_collision_damage_es(info : UpdateStageInfoAct;
                                      eid : EntityId;
                                      vehicle_seats__seatEids : EidList;
                                      net_phys__atTick : int;
                                      net_phys__currentStateVelocity : float3;
                                      net_phys__previousStateVelocity : float3;
                                      vehicle_acceleration__tick : int;
                                      transform : float3x4;
                                      vehicle_seat_damage__minVelocity : float;
                                      vehicle_seat_damage__velocityMult : float;
                                      vehicle_seat_damage__maxDmgPercent : float)
  if net_phys__atTick == vehicle_acceleration__tick
    return
  let prevVelocity = net_phys__previousStateVelocity
  let curVelocity = net_phys__currentStateVelocity
  let deltaVel = curVelocity - prevVelocity
  let deltaSpdSq = length_sq(deltaVel)
  if deltaSpdSq < square(vehicle_seat_damage__minVelocity)
    return
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if ownerEid == INVALID_ENTITY_ID
      continue
    sendEvent(ownerEid, [[EventOnCollision vel=deltaVel * vehicle_seat_damage__velocityMult,
                                           pvel=prevVelocity, pos=transform[3], offender = eid,
                                           cvel = curVelocity, dt = info.dt,
                                           damage = vehicle_seat_damage__maxDmgPercent]])
