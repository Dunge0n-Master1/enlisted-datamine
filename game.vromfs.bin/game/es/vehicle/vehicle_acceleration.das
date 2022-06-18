require ecs
require math
require math.base
require DagorMath

[es]
def vehicle_acceleration_es(info : UpdateStageInfoAct;
                            var vehicle_acceleration__tick : int&;
                            var vehicle_acceleration__velocity : float3&;
                            var vehicle_acceleration__acceleration : float3&;
                            var vehicle_acceleration__viscAcceleration : float3&;
                            var vehicle_acceleration__counterAccel : float3&;
                            net_phys__atTick : int;
                            net_phys__timeStep : float;
                            net_phys__currentStateVelocity : float3;
                            vehicle_acceleration__accelVisc : float = 0.2f;
                            vehicle_acceleration__counterAccelVisc : float = 0.4f)
  let deltaTime : float = float(net_phys__atTick - vehicle_acceleration__tick) * net_phys__timeStep
  var prevAccel = vehicle_acceleration__viscAcceleration
  prevAccel = approach(prevAccel, vehicle_acceleration__acceleration + vehicle_acceleration__counterAccel, info.dt,
      vehicle_acceleration__accelVisc)
  vehicle_acceleration__viscAcceleration = prevAccel
  vehicle_acceleration__counterAccel = approach(vehicle_acceleration__counterAccel,
                                                  -vehicle_acceleration__acceleration, info.dt,
                                                  vehicle_acceleration__counterAccelVisc)

  if deltaTime <= 0.f
    return

  let prevVelocity = vehicle_acceleration__velocity
  let curVelocity = net_phys__currentStateVelocity
  vehicle_acceleration__velocity = curVelocity
  vehicle_acceleration__acceleration = (curVelocity - prevVelocity) * safeinv(deltaTime)
  vehicle_acceleration__tick = net_phys__atTick
