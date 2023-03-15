require ecs
require math
require math.base
require DagorMath
require DagorMathUtils
require DagorInput
require DagorSystem
require TouchInput
require Gun
require GridCollision
require HumanPhys
require EnlistedHuman
require EnlistedWeapon
require AnimV20
require GeomNodeTree
require CollRes
require Dacoll
require SmokeOccluder
require RendInst
require game.utils.team
require game.es.events
require common_shooter.es.input.aim_assist_common
require common_shooter.es.human_weap_common


[es(tag=input, on_appear)]
def aim_assist_init_es(evt : Event;
                       var aim_assist__targetMaxAngle : float&;
                       aim_assist__slowdownMaxAngle : float = 0.0;
                       aim_assist__onAimingStartAngles : float2 = float2(0.0, 0.0);
                       aim_assist__rotationAimMaxAngle : float = 0.0)
  aim_assist__targetMaxAngle = max(aim_assist__targetMaxAngle, aim_assist__slowdownMaxAngle)
  aim_assist__targetMaxAngle = max(aim_assist__targetMaxAngle, aim_assist__onAimingStartAngles.y)
  aim_assist__targetMaxAngle = max(aim_assist__targetMaxAngle, aim_assist__rotationAimMaxAngle)


[es(on_appear)]
def aim_assist_node_load_es(evt : Event;
                            eid : EntityId;
                            animchar : AnimcharBaseComponent;
                            aim_assist_target__nodeName : string;
                            var aim_assist_target__nodeIdx : int&)
  aim_assist_target__nodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, aim_assist_target__nodeName)
  if aim_assist_target__nodeIdx < 0
    logerr("aim_assist_target__nodeName '{aim_assist_target__nodeName}' not found in entity {eid}='{getEntityTemplateName(eid)}'")


[es(tag=input, after=(human_input_es, human_input_attached_gun_es), before=after_input_sync)]
def aim_assist_target_es(info : UpdateStageUpdateInput;
                         eid : EntityId;
                         human_weap__currentGunEid : EntityId;
                         human_weap__currentGunModEids : EidList;
                         human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                         human_net_phys : HumanActor;
                         team : int;
                         human_input__aimAngle : float2&;
                         aim_assist__enabled : bool;
                         aim_assist__targetMaxDist : float;
                         aim_assist__targetMaxAngle : float;
                         aim_assist__targetConeWidth : float;
                         var aim_assist__targetEid : EntityId&;
                         var aim_assist__targetAngleCos : float&;
                         var aim_assist__targetDist : float&;
                         var aim_assist__targetDir : float3&;
                         aim_assist__gunmodZoomFactorMult : float = 0.5)
  aim_assist__targetEid = INVALID_ENTITY_ID
  if !aim_assist__enabled || !is_human_allowed_shooting(eid, human_attached_gun__attachedGunEid, human_net_phys)
    return
  if !is_control_bit_set(human_net_phys.phys.producedCT, HumanPhysControlType HCT_AIM) && !is_control_bit_set(human_net_phys.phys.producedCT, HumanPhysControlType HCT_ZOOM_VIEW)
    return

  let shootDir = angles_to_dir(human_input__aimAngle)
  var shootPos : float3
  ecs::query(human_attached_gun__attachedGunEid != INVALID_ENTITY_ID ? human_attached_gun__attachedGunEid : human_weap__currentGunEid) <| $ [es] (gun : Gun)
    shootPos = gun.gunTm[3]

  var targetMaxDist = aim_assist__targetMaxDist
  for modEid in human_weap__currentGunModEids
    ecs::query(modEid) <| $ [es(REQUIRE=gunScope)] (gunmod__zoomFactor : float)
      targetMaxDist *= max(gunmod__zoomFactor * aim_assist__gunmodZoomFactorMult, aim_assist__targetMaxDist)

  var targets <- get_assist_targets(shootPos, shootDir, aim_assist__targetMaxDist, aim_assist__targetConeWidth * 1.5, cos(deg_to_rad(aim_assist__targetMaxAngle)), team)
  for target in targets
    var t = target.dist + 0.5
    var norm : float3
    if traceray_normalized(shootPos, target.dir, t, norm)
      continue
    if rayhit_entities_in_grid(ecs_hash("vehicles"), shootPos, target.dir, t, INVALID_ENTITY_ID)
      continue
    if traceTransparencyRayRIGenNormalized(shootPos, target.dir, target.dist, 0.01)
      continue
    if rayhit_smoke_occluders(shootPos, target.pos)
      continue
    aim_assist__targetEid = target.eid
    aim_assist__targetAngleCos = target.dp
    aim_assist__targetDist = target.dist
    aim_assist__targetDir = target.dir
    break


[es(tag=input, after=aim_assist_target_es, before=after_input_sync)]
def aim_assist_slowdown_es(info : UpdateStageUpdateInput;
                           var human_input__aimingSensMult : float&;
                           aim_assist__targetEid : EntityId;
                           aim_assist__targetAngleCos : float;
                           aim_assist__targetDist : float;
                           aim_assist__targetConeWidth : float;
                           aim_assist__slowdownEnabled : bool;
                           aim_assist__slowdownMaxAngle : float;
                           aim_assist__slowdownSensMult : float)
  human_input__aimingSensMult = 1.0
  if !aim_assist__slowdownEnabled || !aim_assist__targetEid
    return
  let assistProgress = get_assist_angle_progress(aim_assist__targetDist, aim_assist__targetAngleCos,
                                                 aim_assist__slowdownMaxAngle, aim_assist__targetConeWidth)
  if assistProgress != 0.0
    human_input__aimingSensMult = aim_assist__slowdownSensMult


[es(tag=input, after=aim_assist_slowdown_es, before=after_input_sync)]
def aim_assist_on_aim_start_es(info : UpdateStageUpdateInput;
                               human_net_phys : HumanActor;
                               var human_input__aimAngle : float2&;
                               aim_assist__targetEid : EntityId;
                               aim_assist__targetConeWidth : float;
                               aim_assist__targetAngleCos : float;
                               aim_assist__targetDist : float;
                               aim_assist__targetDir : float3&;
                               aim_assist__onAimingStartEnabled : bool;
                               aim_assist__onAimingStartAngles : float2;
                               var aim_assist__onAimingStartProgress : float&)
  if !aim_assist__targetEid
    return

  if aim_assist__onAimingStartEnabled && aim_assist__targetEid != INVALID_ENTITY_ID
    let aimProgress = lerp(human_net_phys.phys.previousState.aimPosition,
                           human_net_phys.phys.currentState.aimPosition,
                           get_phys_interpk_clamped(human_net_phys.phys, info.curTime))
    if human_net_phys.phys.currentState.aimPosition > human_net_phys.phys.previousState.aimPosition && aimProgress > aim_assist__onAimingStartProgress
      let minAngleCheck = get_assist_angle_progress(aim_assist__targetDist, aim_assist__targetAngleCos,
                                                    aim_assist__onAimingStartAngles.x, aim_assist__targetConeWidth)
      let maxAngleCheck = get_assist_angle_progress(aim_assist__targetDist, aim_assist__targetAngleCos,
                                                    aim_assist__onAimingStartAngles.y, aim_assist__targetConeWidth)
      if (minAngleCheck == 0.0 || aim_assist__onAimingStartProgress > 0.f) && maxAngleCheck != 0.0
        let aimAssist = aimProgress - aim_assist__onAimingStartProgress
        let wishAngle = dir_to_angles(aim_assist__targetDir)
        human_input__aimAngle += angle_diff(human_input__aimAngle, wishAngle) * aimAssist
        aim_assist__onAimingStartProgress = aimProgress


[es(tag=input, after=aim_assist_on_aim_start_es, before=after_input_sync)]
def aim_assist_on_aim_start_reset_es(info : UpdateStageUpdateInput;
                                     human_net_phys : HumanActor;
                                     var aim_assist__onAimingStartProgress : float&;
                                     aim_assist__onAimingResetTime = 1.f)
  if human_net_phys.phys.currentState.aimPosition <= human_net_phys.phys.previousState.aimPosition
    aim_assist__onAimingStartProgress -= safediv(info.dt, aim_assist__onAimingResetTime)
    aim_assist__onAimingStartProgress = max(0.f, aim_assist__onAimingStartProgress)


[es(tag=input, after=aim_assist_on_aim_start_reset_es, before=after_input_sync)]
def aim_assist_rotating_aim_es(info : UpdateStageUpdateInput;
                               human_input__aimAngle : float2;
                               var human_input__aimAngleOffset : float2&;
                               human_input__aim : int;
                               human_input__touch_aim : float2 = float2();
                               human_weap__currentGunEid : EntityId;
                               human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                               aim_assist__targetEid : EntityId;
                               aim_assist__targetConeWidth : float;
                               aim_assist__targetAngleCos : float;
                               aim_assist__targetDist : float;
                               aim_assist__targetDir : float3&;
                               aim_assist__rotationAimEnabled : bool;
                               aim_assist__rotationAimMaxAngle : float;
                               var aim_assist__rotationTargetEid : EntityId&;
                               var aim_assist__rotationTargetNodeId : int&;
                               aim_assist__rotationTargetNodeMaxAngle : float;
                               aim_assist__rotationVisc : float)
  if !aim_assist__rotationAimEnabled || !aim_assist__targetEid
    return

  let aAim = get_analog_stick_action_state(uint16(human_input__aim))
  let touchAim = float2(human_input__touch_aim.x, human_input__touch_aim.y)
  let isManualAiming = aAim.x != 0.0 || aAim.y != 0.0 || touchAim.x != 0.0 || touchAim.y != 0.0
  if isManualAiming
    ecs::query(aim_assist__targetEid) <| $ [es] (collres : CollisionResource;
                                                 animchar : AnimcharBaseComponent;
                                                 transform : float3x4)
      let shootDir = angles_to_dir(human_input__aimAngle)
      var shootPos : float3
      ecs::query(human_attached_gun__attachedGunEid != INVALID_ENTITY_ID ? human_attached_gun__attachedGunEid : human_weap__currentGunEid) <| $ [es] (gun : Gun)
        shootPos = gun.gunTm[3]

      aim_assist__rotationTargetNodeId = -1
      var bestCos = cos(deg_to_rad(aim_assist__rotationTargetNodeMaxAngle))
      for ni in range(0, collres_get_nodesCount(collres))
        var ntm : float3x4
        collres_get_collision_node_tm(collres, ni, transform, animchar.nodeTree, ntm)
        let nodeDir = normalize(ntm[3] - shootPos)
        let nodeAngleCos = dot(shootDir, nodeDir)
        if nodeAngleCos > bestCos
          bestCos = nodeAngleCos
          aim_assist__rotationTargetEid = aim_assist__targetEid
          aim_assist__rotationTargetNodeId = ni
    return

  let assistProgress = get_assist_angle_progress(aim_assist__targetDist, aim_assist__targetAngleCos,
                                                 aim_assist__rotationAimMaxAngle, aim_assist__targetConeWidth)
  if assistProgress != 0.0
    var wishDir = aim_assist__targetDir
    if aim_assist__targetEid != aim_assist__rotationTargetEid
      aim_assist__rotationTargetNodeId = -1

    if aim_assist__rotationTargetNodeId != -1
      ecs::query(aim_assist__targetEid) <| $ [es] (collres : CollisionResource;
                                                   animchar : AnimcharBaseComponent;
                                                   transform : float3x4)
        var shootPos : float3
        ecs::query(human_attached_gun__attachedGunEid != INVALID_ENTITY_ID ? human_attached_gun__attachedGunEid : human_weap__currentGunEid) <| $ [es] (gun : Gun)
          shootPos = gun.gunTm[3]

        var ntm : float3x4
        collres_get_collision_node_tm(collres, aim_assist__rotationTargetNodeId, transform, animchar.nodeTree, ntm)
        wishDir = normalize(ntm[3] - shootPos)

    let wishAngle = dir_to_angles(wishDir)
    let wishOffset = angle_diff(human_input__aimAngle, wishAngle)
    human_input__aimAngleOffset = approach(human_input__aimAngleOffset, wishOffset, info.dt, aim_assist__rotationVisc)
  else
    human_input__aimAngleOffset = approach(human_input__aimAngleOffset, float2(0.f, 0.f), info.dt, aim_assist__rotationVisc)
    aim_assist__rotationTargetEid = INVALID_ENTITY_ID
    aim_assist__rotationTargetNodeId = -1
  