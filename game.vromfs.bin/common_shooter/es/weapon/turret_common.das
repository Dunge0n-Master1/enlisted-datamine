module turret_common shared
require ecs
require DagorMathUtils


def turret_calc_shoot_angles(vehicle_pos : float3&;
                             aim_pos : float3&)
  let shootFromPos = vehicle_pos + float3(0.0, 2.0, 0.0)
  let shootDir = normalize(aim_pos - shootFromPos)
  return dir_to_angles(shootDir)