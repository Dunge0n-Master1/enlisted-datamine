require ecs
require vehicle
require PhysVars
require DagorMath
require DagorSystem

[es(tag=render, on_appear, before=anim_phys_init_es)]
def vehicle_speedometer_anim_init_es(evt : Event;
                                     eid : EntityId;
                                     vehicle_anim__speedometerVarName : string;
                                     var vehicle_anim__speedometerVarId : int&;
                                     var phys_vars : PhysVars&)
  vehicle_anim__speedometerVarId = registerVar(phys_vars, vehicle_anim__speedometerVarName, 0.f)
  if vehicle_anim__speedometerVarId <= -1
    logerr("Anim Var '{vehicle_anim__speedometerVarName}' not exist in entity '{getEntityTemplateName(eid)}'")

[es(tag=render, after=vehicle_input_driver_es, REQUIRE=heroVehicle)]
def vehicle_speedometer_anim_es(info : UpdateStageInfoAct;
                                animchar__updatable : bool;
                                vehicle_net_phys : VehiclePhysActor;
                                vehicle_anim__speedometerVarId : int;
                                vehicle_anim__speedometerMinMax : float2;
                                var phys_vars : PhysVars&)
  if !animchar__updatable
    return

  assume phys = vehicle_net_phys.phys
  let interpk = get_phys_interpk_clamped(phys, info.curTime)
  let speedPrev = dot(float3(phys.previousState.velocity), quat_get_forward(phys.previousState.location.O.quat))
  let speedCur = dot(float3(phys.currentState.velocity), quat_get_forward(phys.currentState.location.O.quat))
  let speed = lerp(speedPrev, speedCur, interpk)
  let minMax = vehicle_anim__speedometerMinMax
  setVar(phys_vars, vehicle_anim__speedometerVarId, cvt(speed, minMax.x, minMax.y, 0f, 1f))
