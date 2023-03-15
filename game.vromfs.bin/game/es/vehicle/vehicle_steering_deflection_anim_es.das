require ecs
require math.base
require PhysVars
require vehicle
require DagorMath
require vehicle
require enlisted.events_enlisted

[es(tag=render, on_appear, before=anim_phys_init_es)]
def steering_deflection_anim_init(evt : Event;
                                  vehicle_anim__steeringDeflection : string;
                                  var vehicle_anim__steeringDeflectionId : int&;
                                  var phys_vars : PhysVars&)
  vehicle_anim__steeringDeflectionId = registerVar(phys_vars, vehicle_anim__steeringDeflection, 0.f)

[es(tag=render, after=vehicle_input_driver_es)]
def steering_deflection_anim_input(info : ParallelUpdateFrameDelayed;
                                   animchar__updatable : bool;
                                   vehicle_net_phys : VehiclePhysActor;
                                   vehicle_anim__steeringDeflectionId : int;
                                   vehicle_anim__steeringDeflectionLimit : float2;
                                   vehicle_anim__steeringDeflectionViscosity : float;
                                   var vehicle_anim__steeringDeflectionValue : float&;
                                   var phys_vars : PhysVars&)
  if !animchar__updatable
    return
  let lim = vehicle_anim__steeringDeflectionLimit
  let interpk = get_phys_interpk_clamped(vehicle_net_phys.phys, info.curTime)
  let wishSteering = lerp(vehicle_net_phys.phys.previousState.steering, vehicle_net_phys.phys.currentState.steering, interpk)

  let wasSteering = vehicle_anim__steeringDeflectionValue
  let steering    = approach(wasSteering, wishSteering, info.dt, vehicle_anim__steeringDeflectionViscosity)
  vehicle_anim__steeringDeflectionValue = steering

  setVar(phys_vars, vehicle_anim__steeringDeflectionId, cvt(steering, -1f, 1f, lim.x, lim.y))
