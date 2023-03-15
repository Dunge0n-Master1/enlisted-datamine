require ecs
require vehicle
require PhysVars
require DagorMath
require enlisted.events_enlisted


[es(tag=render, on_appear, before=anim_phys_init_es)]
def vehicle_speedometer_anim_init_es(evt : Event;
                                     vehicle_anim__speedometerVarName : string;
                                     vehicle_anim__speedometerMinMax : float2;
                                     var vehicle_anim__speedometerVarId : int&;
                                     var phys_vars : PhysVars&)
  vehicle_anim__speedometerVarId = registerVar(phys_vars, vehicle_anim__speedometerVarName, vehicle_anim__speedometerMinMax.x)

[es(tag=render, after=vehicle_input_driver_es, REQUIRE=vehicleWithWatched)]
def vehicle_speedometer_anim_es(info : ParallelUpdateFrameDelayed;
                                animchar__updatable : bool;
                                vehicle_net_phys : VehiclePhysActor;
                                vehicle_anim__speedometerVarId : int;
                                vehicle_anim__speedometerMinMax : float2;
                                vehicle_anim__speedometerUnitsMult : float;
                                var phys_vars : PhysVars&)
  if !animchar__updatable
    return

  assume phys = vehicle_net_phys.phys
  let interpk = get_phys_interpk_clamped(phys, info.curTime)
  let speedPrev = dot(float3(phys.previousState.velocity), quat_get_forward(phys.previousState.location.O.quat))
  let speedCur = dot(float3(phys.currentState.velocity), quat_get_forward(phys.currentState.location.O.quat))
  let speed = lerp(speedPrev, speedCur, interpk) * vehicle_anim__speedometerUnitsMult
  let minMax = vehicle_anim__speedometerMinMax
  setVar(phys_vars, vehicle_anim__speedometerVarId, clamp(speed, minMax.x, minMax.y))
