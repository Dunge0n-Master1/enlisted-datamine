require ecs
require app
require DagorMath
require DngPhysObj
require game.es.events
require math.base

[es(after=phys_obj_parachute, REQUIRE=(hasParachute, parachuteDeployed))]
def phys_obj_parachute_wind(evt : CmdPostPhysUpdate;
                            transform : float3x4;
                            human_parachute__eid : EntityId;
                            human_parachute_wind__speed : float;
                            human_parachute_wind__deadZone : float;
                            human_parachute_wind__landingPoint : float2;
                            var phys_obj_net_phys : PhysObjActor)
  query(human_parachute__eid) <| $ [es] (parachute__deployedAtTime : float;
                                         parachute__deployTime : float)
    let windTargetPos = human_parachute_wind__landingPoint
    if length_sq(transform[3].xz - windTargetPos) < square(human_parachute_wind__deadZone)
      return
    let windSpeedScaled = cvt(get_sync_time(), parachute__deployedAtTime, parachute__deployedAtTime + parachute__deployTime,
                              0.0, human_parachute_wind__speed)
    let windVelocity = normalize(windTargetPos - transform[3].xz) * windSpeedScaled

    assume curVelocity = phys_obj_net_phys.phys.currentState.velocity
    let afterWindVelocity = float3(windVelocity.x, curVelocity.y, windVelocity.y)

    curVelocity = afterWindVelocity
