options no_aot
require ecs
require EnlistedHuman
require HumanPhys
require GamePhys
require DagorDebug3D
require DagorConsole
require math
require math.base
require math.ang
require DagorMath
require DagorMathUtils
require game.utils.hero
require common_shooter.es.human.bipod_common

[console_cmd(name="bipod.debug")]
def bipod_debug()
  let hero = get_controlled_hero()
  if has(hero, "bipodDebug")
    removeSubTemplate(hero, "bipod_debug")
  else
    addSubTemplate(hero, "bipod_debug")


def draw_point(pos : float3; color : E3DCOLOR; radius : float = 0.05)
  draw_cached_debug_sphere(pos, radius, color, 24)


def draw_line(from, to, color)
  draw_cached_debug_line(from, to, color)

[es(no_order, tag=(dev, render), REQUIRE=(hero, bipodDebug))]
def bipod_debug_human_sphere_points_es(info : UpdateStageInfoRenderDebug;
                                       bipod__anchorDir : float3;
                                       bipod__anchorPos : float3;
                                       bipod__anchorNormal : float3;
                                       bipod__enabled : bool;
                                       transform : float3x4;
                                       human_weap__currentGunEid : EntityId;
                                       human_net_phys : HumanActor)
  if !bipod__enabled
    return

  var yawLimits = float2(0.f)

  let body_points = bipod_solve_limits(bipod__anchorDir, bipod__anchorPos, bipod__anchorNormal,
                                       transform, human_weap__currentGunEid, human_net_phys, yawLimits)

  begin_draw_cached_debug_lines(true, true, false)

  draw_point(body_points.headMin, E3DCOLOR(0xFF0000FF), sphereRadius)
  draw_point(body_points.bodyMin, E3DCOLOR(0xFF0000FF), bodySphereRadius)
  draw_point(body_points.legsMin, E3DCOLOR(0xFF0000FF), sphereRadius)

  draw_point(body_points.headMax, E3DCOLOR(0xFFFF0000), sphereRadius)
  draw_point(body_points.bodyMax, E3DCOLOR(0xFFFF0000), bodySphereRadius)
  draw_point(body_points.legsMax, E3DCOLOR(0xFFFF0000), sphereRadius)

  end_draw_cached_debug_lines()

[es(tag=(dev, render), REQUIRE=(hero, bipodDebug), after=bipod_human_act_es)]
def bipod_debug_es(info : UpdateStageInfoRenderDebug;
                   human_net_phys : HumanActor;
                   human_weap__currentGunEid : EntityId;
                   human__aimTm : float3x4;
                   bipod__enabled : bool;
                   bipod__anchorPos : float3;
                   bipod__anchorDir : float3;
                   bipod__anchorNormal : float3;
                   bipod__isCrawl : bool;
                   bipod__crawlLimit : float4;
                   bipod__yawLimit : float2)
  begin_draw_cached_debug_lines(true, true, false)

  var tm : float3x4
  location_toTM(human_net_phys.phys.currentState.location, tm)
  draw_point(tm[3], E3DCOLOR(0xFF00FF00))

  var aasTm : float3x4
  location_toTM(human_net_phys.phys.authorityApprovedState.location, aasTm)
  draw_point(aasTm[3], E3DCOLOR(0xFFFF0000))

  var paasTm : float3x4
  location_toTM(human_net_phys.phys.authorityApprovedPartialState.location, paasTm)
  draw_point(paasTm[3], E3DCOLOR(0xFF0000FF))

  let aimAngle = dir_to_angles(human_net_phys.phys.appliedCT.wishShootDir)

  let walkDir = normalize(cross(cross(human_net_phys.phys.currentState.walkNormal, human__aimTm[0]), human_net_phys.phys.currentState.walkNormal))

  draw_line(tm[3], tm[3] + walkDir, E3DCOLOR(0xFFFF00FF))

  var prevHumanTm, prevHumanItm : float3x4
  location_toTM(human_net_phys.phys.previousState.location, prevHumanTm)
  prevHumanItm = inverse(prevHumanTm)

  var gunTm : float3x4
  calc_gun_tm(gunTm, human_net_phys, prevHumanTm, aimAngle.y)

  query(human_weap__currentGunEid) <| $ [es] (gun__bipodOffset : float3)
    draw_point(gunTm * gun__bipodOffset, E3DCOLOR(0xFFFFFF00))
  draw_point(gunTm[3], E3DCOLOR(0xFFFFFFFF))

  if !bipod__enabled
    end_draw_cached_debug_lines()
    return

  draw_point(bipod__anchorPos, E3DCOLOR(0xFF0000FF))
  draw_line(bipod__anchorPos, bipod__anchorPos + bipod__anchorDir, E3DCOLOR(0xFF0000FF))
  draw_line(bipod__anchorPos, bipod__anchorPos + bipod__anchorNormal, E3DCOLOR(0xFF0000FF))

  let anchorAngleYaw = dir_to_angles(bipod__anchorDir).x

  let leftAngleLimit = angles_to_dir(float2(anchorAngleYaw +
                                            (bipod__isCrawl ?
                                            clamp_ang(bipod__yawLimit[0], deg_to_rad(bipod__crawlLimit[0]), 0.) :
                                            bipod__yawLimit[0]),
                                            0.))
  let rightAngleLimit = angles_to_dir(float2(anchorAngleYaw +
                                             (bipod__isCrawl ?
                                             clamp_ang(bipod__yawLimit[1], 0., deg_to_rad(bipod__crawlLimit[1])) :
                                             bipod__yawLimit[1]),
                                             0.))

  draw_line(bipod__anchorPos, bipod__anchorPos + leftAngleLimit, E3DCOLOR(0xFFFF0000))
  draw_line(bipod__anchorPos, bipod__anchorPos + rightAngleLimit, E3DCOLOR(0xFFFF0000))

  end_draw_cached_debug_lines()