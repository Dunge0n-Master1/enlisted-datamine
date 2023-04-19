require ecs
require DagorMath
require game.es.events
require DngPhysObj
require math.base

[es(REQUIRE_NOT=human_parachute_wind__landingPoint)]
def obj_horizontal_air_resistance_es(evt : CmdPostPhysUpdate;
                                     var horizontal_air_resistance__isOn : bool&;
                                     horizontal_air_resistance__accel : float;
                                     var phys_obj_net_phys : PhysObjActor)
  if !horizontal_air_resistance__isOn
    return
  assume curVelocity = phys_obj_net_phys.phys.currentState.velocity
  let horizontalVelocity = float3(curVelocity.x, 0., curVelocity.z)
  let horizontalSpeed = length(horizontalVelocity)
  let horizontalDir = horizontalVelocity * safeinv(horizontalSpeed)
  let horizSpeedAfterAccel = horizontalSpeed - evt.dt * horizontal_air_resistance__accel
  if horizSpeedAfterAccel < 0.
    horizontal_air_resistance__isOn = false
  else
    curVelocity += horizontalDir * (horizSpeedAfterAccel - horizontalSpeed)

[es]
def obj_horizontal_air_resistance_wih_target(evt : CmdPostPhysUpdate;
                                             human_parachute_wind__landingPoint : float2;
                                             horizontal_air_resistance__accel : float;
                                             var horizontal_air_resistance__isOn : bool&;
                                             var phys_obj_net_phys : PhysObjActor)
  if !horizontal_air_resistance__isOn
    return
  assume curVelocity = phys_obj_net_phys.phys.currentState.velocity
  let pos = float3(phys_obj_net_phys.phys.currentState.location.P).xz
  let horizontalVelocity = float3(curVelocity.x, 0., curVelocity.z)
  let horizontalSpeed = length(horizontalVelocity)
  let horizontalDir = horizontalVelocity * safeinv(horizontalSpeed)
  let distToTarget = dot(human_parachute_wind__landingPoint - pos, horizontalDir.xz)
  let trueAcc = square(horizontalSpeed) * 0.5 * safeinv(distToTarget)
  let acc = max(horizontal_air_resistance__accel, trueAcc)
  let horizSpeedAfterAccel = horizontalSpeed - evt.dt * acc

  if horizSpeedAfterAccel < 0.
    horizontal_air_resistance__isOn = false
  else
    curVelocity += horizontalDir * (horizSpeedAfterAccel - horizontalSpeed)
