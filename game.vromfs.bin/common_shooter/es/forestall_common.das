module forestall_common shared
require ecs
require BallisticsProps
require DaWeapons

struct ForestallParam
  dt : float = 0.01
  iterMax : int = 5
  maxTime : float = 60.0

struct ForestallRes
  pos : float3 = float3(0, 0, 0)
  valid : bool = false

def get_forestall_pos(shooter_pos : float3;
                      shooter_vel : float3;
                      ballistics_props : ProjectileProps;
                      muzzle_velocity : float;
                      target_pos : float3;
                      target_vel : float3;
                      target_acc : float3 = float3(0, 0, 0);
                      forestall : ForestallParam = ForestallParam();
                      precision_sq : float = 0.1)
  var outShooterDir : float3
  var outFlightTime : float
  var res = ForestallRes()
  if aim_projectile(ballistics_props, shooter_pos, shooter_vel, target_pos, target_vel, target_acc, muzzle_velocity, precision_sq,
                    true, // bullet gravity
                    true, // air friction
                    forestall.dt, forestall.maxTime, forestall.iterMax, outShooterDir, outFlightTime)
    res.pos = shooter_pos + outShooterDir * length((target_pos + target_vel * outFlightTime) - shooter_pos)
    res.valid = true
  return res