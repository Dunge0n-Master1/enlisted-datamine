module common_shooter_walker_nodes_common shared

require ecs
require math.base
require game.es.battle_area_common
require RendInst
require DagorMath
require DagorMathUtils

def is_point_safe(pos : float3; member_team : int)
  if !has_active_human_battle_area_at(pos, member_team)
    return false
  let danger = find_query() <| $ [es] (transform : float3x4; sphere_zone__radius : float;
                                       dmgzone__damage, dmgzone__fireAffect : float)
    if length_sq(inverse(transform) * pos) <= square(sphere_zone__radius)
      if dmgzone__damage > 0. || dmgzone__fireAffect > 0.
        return true
    return false;
  return !danger
