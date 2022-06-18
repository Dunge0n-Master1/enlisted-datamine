options no_aot
require ecs
require game.utils.hero
require math.base
require math.ang
require DagorMath
require DagorMathUtils
require Gun
require HumanPhys
require EnlistedHuman
require AnimV20
require GeomNodeTree
require CollRes
require Dacoll
require SmokeOccluder
require RendInst
require game.utils.team
require DagorConsole
require DagorDebug3D
require DagorSystem
require strings
require common_shooter.es.input.aim_assist_common


[console_cmd(name="aim_assist.debug_draw")]
def debug_aim_assist_cmd(aim_assist_debug_draw : bool = true)
  let tmpl = "aim_assist_debug_draw"
  ecs::createTemplate(tmpl, "", false) <| $(var cmp : ecs::ComponentsMap)
    set(cmp, "aim_assist__debugDraw", false)
  addSubTemplate(get_controlled_hero(), tmpl) <| $(var init)
    set(init, "aim_assist__debugDraw", aim_assist_debug_draw)


[es(tag=render, tag=dev, no_order)]
def aim_assist_debug_es(evt : UpdateStageInfoRenderDebug;
                        human_net_phys : HumanActor;
                        human_weap__currentGunEid : EntityId;
                        human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                        aim_assist__debugDraw : bool;
                        aim_assist__targetEid : EntityId;
                        aim_assist__targetConeLength : float;
                        aim_assist__onAimingStartAngles : float2 = float2();
                        aim_assist__slowdownMaxAngle : float = 0.0;
                        aim_assist__rotationAimMaxAngle : float = 0.0;
                        aim_assist__rotationTargetNodeId : int = -1;
                        aim_assist__rotationTargetNodeMaxAngle : float = 0.0;
                        aim_assist__onAimingStartProgress : float;
                        team : int;
                        human_input__aimAngle : float2&;
                        human__aimTm : float3x4)
  if !aim_assist__debugDraw
    return

  if is_control_bit_set(human_net_phys.phys.producedCT, HumanPhysControlType HCT_AIM) && human_net_phys.phys.currentState.aimPosition < aim_assist__onAimingStartProgress
    logerr("cooldown {int(aim_assist__onAimingStartProgress * 100.0)}%")

  begin_draw_cached_debug_lines(true, true, false)

  let shootDir = angles_to_dir(human_input__aimAngle)
  var shootPos : float3
  ecs::query(human_attached_gun__attachedGunEid != INVALID_ENTITY_ID ? human_attached_gun__attachedGunEid : human_weap__currentGunEid) <| $ [es] (gun : Gun)
    shootPos = gun.gunTm[3]

  let wishTag = "human"
  let myTeam = team
  ecs::query() <| $ [es] (eid : EntityId;
                          collres : CollisionResource;
                          animchar : AnimcharBaseComponent;
                          transform : float3x4;
                          agent_dangers__tag : string;
                          aim_assist_target__nodeIdx : int;
                          aim_assist_target__score : float;
                          team : int;
                          isAlive : bool)
    if !isAlive || agent_dangers__tag != wishTag || is_teams_friendly(myTeam, team) || aim_assist_target__nodeIdx < 0
      return
    let aimPos = geomtree_getNodeWpos(animchar.nodeTree, aim_assist_target__nodeIdx)
    var dir = aimPos - shootPos
    let dist = length(dir)
    dir *= rcp(dist)
    let targetAngleCos = dot(dir, shootDir)
    if targetAngleCos < 0.5
      return

    var t = dist
    var norm : float3
    let traceBlocked = traceray_normalized(shootPos, dir, t, norm)
    if traceBlocked
      return
    let transpBlocked = traceTransparencyRayRIGenNormalized(shootPos, dir, dist, 0.01)
    let smokeBlocked = rayhit_smoke_occluders(shootPos, aimPos)
    let mark = build_string() <| $(var str)
      format(str, "s: %.2f ", aim_assist_target__score)
      format(str, "a: %.2f ", rad_to_deg(safe_acos(targetAngleCos)))
      format(str, "d: %.2f",  dist)
      if transpBlocked
        write(str, " [bush]")
      if smokeBlocked
        write(str, " [smoke]")
    var color = E3DCOLOR(0xFFFFFFFF)
    if transpBlocked || smokeBlocked
      color = E3DCOLOR(0xFFFF2020)
    if eid == aim_assist__targetEid
      color = E3DCOLOR(0xFF20FF20)
    add_debug_text_mark(aimPos, mark, -1, 0f, color)

    if human_net_phys.phys.currentState.aimPosition < 1.0
      if aim_assist__onAimingStartAngles.y > 0.0
        let minRadius = get_assist_radius(dist, aim_assist__onAimingStartAngles.x, aim_assist__targetConeLength)
        let maxRadius = get_assist_radius(dist, aim_assist__onAimingStartAngles.y, aim_assist__targetConeLength)
        draw_cached_debug_circle(aimPos, human__aimTm[1], human__aimTm[2], minRadius, E3DCOLOR(0xFFFFFF20), 24)
        draw_cached_debug_circle(aimPos, human__aimTm[1], human__aimTm[2], maxRadius, E3DCOLOR(0xFFFFFF20), 24)
        if targetAngleCos > cos(deg_to_rad(aim_assist__onAimingStartAngles.y))
          let markPos = aimPos - human__aimTm[1] * ((minRadius + maxRadius * 2.0) / 3.0)
          add_debug_text_mark(markPos, "min-max", -1, 0f, E3DCOLOR(0xFFFFFF20))
    else
      if aim_assist__slowdownMaxAngle > 0.0
        let maxRadius = get_assist_radius(dist, aim_assist__slowdownMaxAngle, aim_assist__targetConeLength)
        draw_cached_debug_circle(aimPos, human__aimTm[1], human__aimTm[2], maxRadius, E3DCOLOR(0xFF20E8FF), 24)
        if eid == aim_assist__targetEid
          let markPos = aimPos - normalize(human__aimTm[1] + human__aimTm[2]) * maxRadius
          add_debug_text_mark(markPos, "slowdown", -1, 0f, E3DCOLOR(0xFF20E8FF))
      if aim_assist__rotationAimMaxAngle > 0.0
        let maxRadius = get_assist_radius(dist, aim_assist__rotationAimMaxAngle, aim_assist__targetConeLength)
        draw_cached_debug_circle(aimPos, human__aimTm[1], human__aimTm[2], maxRadius, E3DCOLOR(0xFFFF20FF), 24)
        if eid == aim_assist__targetEid
          let markPos = aimPos + normalize(human__aimTm[1] - human__aimTm[2]) * maxRadius
          add_debug_text_mark(markPos, "rotation", -1, 0f, E3DCOLOR(0xFFFF20FF))
          var rotTargetPos = aimPos
          if aim_assist__rotationTargetNodeId != -1
            let node = collres_get_node(collres, aim_assist__rotationTargetNodeId)
            if node != null
              var ntm : float3x4
              collres_get_collision_node_tm(collres, aim_assist__rotationTargetNodeId, transform, animchar.nodeTree, ntm)
              rotTargetPos = ntm[3]

          let crossSize = 0.08
          rotTargetPos -= human__aimTm[0] * 0.3
          let d1 = normalize(human__aimTm[1] + human__aimTm[2]) * crossSize
          let d2 = normalize(human__aimTm[1] - human__aimTm[2]) * crossSize
          let a = rotTargetPos + d1
          let b = rotTargetPos + d2
          let c = rotTargetPos - d1
          let d = rotTargetPos - d2
          draw_cached_debug_line(a, c, E3DCOLOR(0xFFFF20FF))
          draw_cached_debug_line(b, d, E3DCOLOR(0xFFFF20FF))
          if aim_assist__rotationTargetNodeMaxAngle > 0.0
            let maxNodeRadius = get_assist_radius(dist, aim_assist__rotationTargetNodeMaxAngle, aim_assist__targetConeLength)
            draw_cached_debug_circle(rotTargetPos, human__aimTm[1], human__aimTm[2], maxNodeRadius, E3DCOLOR(0xFFFF20FF), 24)

  end_draw_cached_debug_lines()


[console_cmd(name="aim_assist.set_on_aim_start", hint="<enabled> <min_angle> <max_angle>")]
def set_aim_assist_on_aim_start_cmd(enabled : bool; min_angle, max_angle : float)
  find_query() <| $ [es(REQUIRE=hero)] (var aim_assist__onAimingStartEnabled : bool&;
                                        var aim_assist__onAimingStartAngles : float2&;
                                        var aim_assist__targetMaxAngle : float&)
    aim_assist__onAimingStartEnabled = enabled
    aim_assist__onAimingStartAngles = float2(min_angle, max_angle)
    aim_assist__targetMaxAngle = max(aim_assist__targetMaxAngle, max_angle)
    return true


[console_cmd(name="aim_assist.set_slowdown", hint="<enabled> <max_angle>")]
def set_aim_assist_slowdown_cmd(enabled : bool; max_angle : float)
  find_query() <| $ [es(REQUIRE=hero)] (var aim_assist__slowdownEnabled : bool&;
                                        var aim_assist__slowdownMaxAngle : float&;
                                        var aim_assist__targetMaxAngle : float&)
    aim_assist__slowdownEnabled = enabled
    aim_assist__slowdownMaxAngle = max_angle
    aim_assist__targetMaxAngle = max(aim_assist__targetMaxAngle, max_angle)
    return true


[console_cmd(name="aim_assist.set_rotation", hint="<enabled> <max_angle> <max_node_angle> <viscosity>")]
def set_aim_assist_rotation_cmd(enabled : bool; max_angle, max_node_angle, viscosity : float)
  find_query() <| $ [es(REQUIRE=hero)] (var aim_assist__rotationAimEnabled : bool&;
                                        var aim_assist__rotationAimMaxAngle : float&;
                                        var aim_assist__rotationTargetNodeMaxAngle : float&;
                                        var aim_assist__rotationVisc : float&;
                                        var aim_assist__targetMaxAngle : float&)
    aim_assist__rotationAimEnabled = enabled
    aim_assist__rotationAimMaxAngle = max_angle
    aim_assist__rotationTargetNodeMaxAngle = max_node_angle
    aim_assist__rotationVisc = viscosity
    aim_assist__targetMaxAngle = max(aim_assist__targetMaxAngle, max_angle)
    return true
