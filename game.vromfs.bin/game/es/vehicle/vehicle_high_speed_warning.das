require ecs
require math.base
require DagorMath
require EnlistedPlane
require enlisted.events_enlisted


[es(tag=render, no_order, REQUIRE=heroVehicle)]
def plane_high_speed_warning(info : ParallelUpdateFrameDelayed;
                             plane_net_phys : PlaneActor;
                             vehicle__highSpeedWarningLimits : float2;
                             var vehicle__isHighSpeedWarningEnabled : bool&)
  let currentSpeedSq = length_sq(plane_net_phys.phys.currentState.velocity)

  if currentSpeedSq > square(vehicle__highSpeedWarningLimits.y)
    vehicle__isHighSpeedWarningEnabled = true
    return
  if currentSpeedSq < square(vehicle__highSpeedWarningLimits.x)
    vehicle__isHighSpeedWarningEnabled = false