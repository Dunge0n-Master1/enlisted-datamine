module aim_assist_common shared
require math
require math.ang
require math.base
require DagorMath


def get_min_assist_angle_cos(dist_to_target, max_assist_angle_cos, assist_cone_base_radius : float) : float
  let tanSq = square(safediv(assist_cone_base_radius, dist_to_target))
  return max(max_assist_angle_cos, sqrt(1.0 / (1.0 + tanSq)))


def get_assist_angle_progress(dist_to_target, angle_to_target_cos, max_assist_angle, assist_cone_end_dist : float) : float
  var assistMaxAngleSin, assistMaxAngleCos : float
  sincos(deg_to_rad(max_assist_angle), assistMaxAngleSin, assistMaxAngleCos)
  let assistConeBaseRadius = assist_cone_end_dist * assistMaxAngleSin / assistMaxAngleCos
  return cvt(angle_to_target_cos, get_min_assist_angle_cos(dist_to_target, assistMaxAngleCos, assistConeBaseRadius), 1.0, 0.0, 1.0)


def get_assist_radius(dist_to_target, max_assist_angle, assist_cone_end_dist : float) : float
  var assistMaxAngleSin, assistMaxAngleCos : float
  sincos(deg_to_rad(max_assist_angle), assistMaxAngleSin, assistMaxAngleCos)
  let assistConeBaseRadius = assist_cone_end_dist * assistMaxAngleSin / assistMaxAngleCos
  let minAngleCos = get_min_assist_angle_cos(dist_to_target, assistMaxAngleCos, assistConeBaseRadius)
  return dist_to_target * tan(safe_acos(minAngleCos))
