require ecs
require common_shooter.es.human_weap_common
require enlisted.events_enlisted
require math.base
require HumanPhys
require EnlistedHuman
require EnlistedWeapon
require EnlistedCamera
require DagorMath
require DagorMathUtils
require DagorSystem
require Gun
require Grid
require GridCollision
require CollisionTraces
require Dacoll
require CollRes
require AnimV20
require GeomNodeTree


def find_object_on_ray(from : float3; dir : float3; var t : float&; ignore_human_eid : EntityId)
  var retEid = INVALID_ENTITY_ID
  using() <| $(var intersections : IntersectedEntities)
    trace_entities_in_grid(ecs_hash("humans"), from, dir, t, ignore_human_eid, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), from, dir, t, ignore_human_eid, intersections, SortIntersections YES)
    for isect in intersections
      if get_bool(isect.eid, "animchar__visible") ?? true
        retEid = isect.eid
        break
  return retEid


[es(REQUIRE=(human_input, human_weap, human_weap__traceInThread), after=(start_async_phys_sim_es, human_weap_ri_trace_wait_job_es))] // after start_async_phys_sim_es to start phys sim job earlier
def human_weap_trace_es(info : ParallelUpdateFrameDelayed;
                        eid : EntityId;
                        human_net_phys : HumanActor;
                        human_weap__prevGunAngles : float2&;
                        var human_weap__traceIntersectedEid : EntityId&;
                        var human_weap__tracerayLen : float&;
                        isDowned : bool = false;
                        isAlive : bool = true)
  if !isAlive || isDowned || human_net_phys.phys.currentState |> human_phys_state_attachedToLadder
    return
  let gunDir = angles_to_dir(human_weap__prevGunAngles)
  let gunEid = get_human_gun_eid(eid)
  if gunEid != INVALID_ENTITY_ID
    query(gunEid) <| $ [es(REQUIRE_NOT=mortar)] ()
      let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
      let camPos = cameraTm[3]
      human_weap__traceIntersectedEid = find_object_on_ray(camPos, gunDir, human_weap__tracerayLen, eid)

[es(after=after_guns_update_sync, REQUIRE=(hero, human_weap))]
def cache_trace_gun_angles(info : UpdateStageInfoAct;
                           eid : EntityId;
                           var human_weap__traceGunAngles : float2&;
                           human_weap__prevGunAngles : float2)
  var shootTm : float3x4
  if human_weap_get_aim_tm(eid, info.curTime, shootTm)
    human_weap__traceGunAngles = dir_to_angles(shootTm[0])
  else
    human_weap__traceGunAngles = human_weap__prevGunAngles

[es(after=human_phys_es, before=after_guns_update_sync, REQUIRE=(hero, human_weap))]
def human_weap_update_es(info : ParallelUpdateFrameDelayed;
                         eid : EntityId;
                         human_weap__gunAngleTau : float;
                         isInVehicle : bool;
                         human_vehicle__isHoldingGunPassenger : bool;
                         human_weap__crawlClampVertAngleRad : float2;
                         human_weap__clampVertAngleRad : float2;
                         human_weap__lockedGrenadeThrowingCounter : int = 0;
                         human_weap__mortarMode : bool = false;
                         human_weap__jumpDeviation : float = 0.;
                         human_weap__changePosDeviationCanAim : float = 0.;
                         human_weap__changePosDeviationCanNotAim : float = 0.;
                         human_phys__afterJumpDelay : float = 0.;
                         human_phys__jumpEndTime : float;
                         human_phys__isInAirLong : bool;
                         isDowned : bool = false;
                         isAlive : bool = true;
                         entity_mods__shotDeviationMult : float = 1.0;
                         entity_mods__rotationShotSpreadDecrMult : float = 1.0;
                         entity_mods__aimingAfterFireMult : float = 1.0;
                         entity_mods__boltActionMult : float = 1.0;
                         entity_mods__deviationBufferSizeMult : float = 1.0;
                         human_use_object__selectedObject : EntityId const? = null;
                         entity_mods__shotDeviationAdd : float = 0.0;
                         human_weap__fastThrowExclusive : bool = true;
                         human_weap__maxParallaxDeviation : float = 10.0;
                         human_weap__extraGunSpeedOnJump : float = 0.0;
                         human_weap__maxGunVisualAngleDeviation : float = 10.;
                         human_unarmed__active : bool = false;
                         human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                         human_weap__tracerayLen : float&;
                         isReplayObserved : Tag const?;
                         var human_net_phys : HumanActor;
                         var transform : float3x4;
                         var human_weap__gunEids : EidList;
                         var human_weap__throwMode : bool&;
                         var human_weap__prevGunAngles : float2&;
                         var human_weap__gunAngleSpeed : float2&)
  if !isAlive || isDowned || human_net_phys.phys.currentState |> human_phys_state_attachedToLadder
    return

  let dt = info.dt
  var atTime = info.curTime

  // Align updates on phys ticks to phys.timeStep for shooting end time synchronization
  // in replay use a appliedCT because producedCT doesn't multicast to all clients
  assume ct = isReplayObserved == null ? human_net_phys.phys.producedCT : human_net_phys.phys.appliedCT
  if ct |> is_control_bit_set(HumanPhysControlType HCT_SHOOT) && !ct.haveUnenqueuedHctShoot
    atTime = floor(atTime / human_net_phys.phys.timeStep) * human_net_phys.phys.timeStep

  let isForReal = true
  let wishGunDir = ct.wishShootDir
  var gunDir = wishGunDir
  var gunAngles = dir_to_angles(gunDir)
  var gunSpeedAng = gunAngles - human_weap__prevGunAngles
  gunSpeedAng.x = norm_s_ang(gunSpeedAng.x)
  let isInAir = (int(human_net_phys.phys.currentState.isInAirHistory) & 1) != 0
  if human_weap__extraGunSpeedOnJump > 0.0 && isInAir
    let humanVel = human_net_phys.phys.currentState.velocity
    let dir = human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM) ? 1.0 : -1.0
    let extraGunSpeedOnJump = human_weap__extraGunSpeedOnJump
    gunSpeedAng.y += dir * cvt(humanVel.y, -1.0, 1.0, -extraGunSpeedOnJump, extraGunSpeedOnJump)
  let gunSpeed = gunSpeedAng * safeinv(dt)
  human_weap__gunAngleSpeed = approach(human_weap__gunAngleSpeed, gunSpeed, dt, human_weap__gunAngleTau)
  human_weap__prevGunAngles = gunAngles

  assume phys = human_net_phys.phys
  if !human_weap__mortarMode
    let vertLimits = phys.currentState.isCrawl ? human_weap__crawlClampVertAngleRad : human_weap__clampVertAngleRad
    apply_gun_angle_offsets(phys, atTime, vertLimits, gunAngles)
  gunDir = angles_to_dir(gunAngles)

  let up = transform[1]
  var horzDir = normalize(gunDir - dot(gunDir, up) * up)

  assume prevState = phys.previousState
  assume curState  = phys.currentState
  if prevState.moveState == HUMoveState EMS_SPRINT || curState.moveState == HUMoveState EMS_SPRINT
    let from = prevState.moveState == HUMoveState EMS_SPRINT ? 1.0 : 0.0
    let to = curState.moveState == HUMoveState EMS_SPRINT ? 1.0 : 0.0
    let interpK = get_phys_interpk_clamped(phys, atTime)
    horzDir = slerp(dir_to_quat(horzDir), dir_to_quat(transform[0]), lerp(from, to, interpK)) |> quat_get_forward()
  transform[0] = horzDir
  transform |> orthonormalize()

  var gunShootDir = gunDir
  let gunEid = get_human_gun_eid(eid)
  if gunEid != INVALID_ENTITY_ID
    query(gunEid) <| $ [es(REQUIRE_NOT=mortar)] (gun : Gun; animchar : AnimcharBaseComponent)
      let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
      let camPos = cameraTm[3]
      let shootTm = gun.shootNodeData |> gun_shoot_node_data_calcShootTm(gunDir, transform, transform)
      let shootPos = shootTm[3]
      gunShootDir = normalize(camPos + gunDir * human_weap__tracerayLen - shootPos)
      let initialGunAngles = dir_to_angles(gunDir)
      var wishGunAngles = dir_to_angles(gunShootDir)
      let angDevRad = deg_to_rad(human_weap__maxParallaxDeviation)
      wishGunAngles.x = clamp(renorm_ang(wishGunAngles.x, initialGunAngles.x), initialGunAngles.x - angDevRad,
                                                                               initialGunAngles.x + angDevRad)
      wishGunAngles.y = clamp(wishGunAngles.y, initialGunAngles.y - angDevRad, initialGunAngles.y + angDevRad)
      gunShootDir = angles_to_dir(wishGunAngles)

      var visualTm : float3x4
      geomtree_getNodeWtmScalar(*animchar.nodeTree, 0/*root*/, visualTm)
      let visualGunDir = normalize(-visualTm[2])
      if !human_weap__throwMode && dot(visualGunDir, gunShootDir) < cos(deg_to_rad(human_weap__maxGunVisualAngleDeviation))
        gunShootDir = visualGunDir

  let updCtx = [[GunUpdateCtx
    dt=dt,
    atTime=atTime,
    isForReal=isForReal,
    eid=eid,
    isDowned=isDowned,
    isThrowingAllowed=human_weap__lockedGrenadeThrowingCounter == 0 && (human_vehicle__isHoldingGunPassenger || !isInVehicle),
    shotDeviationMult=entity_mods__shotDeviationMult,
    rotationShotSpreadDecrMult=entity_mods__rotationShotSpreadDecrMult,
    aimingAfterFireMult=entity_mods__aimingAfterFireMult,
    boltActionMult=entity_mods__boltActionMult,
    shotDeviationAdd=entity_mods__shotDeviationAdd,
    fastThrowExclusive=human_weap__fastThrowExclusive,
    deviationBufferSizeMult=entity_mods__deviationBufferSizeMult]]

  human_weap_gun_update(human_net_phys, human_weap__gunEids, human_weap__throwMode,
                        updCtx, transform, gunDir, gunShootDir, transform,
                        ct, human_use_object__selectedObject,
                        human_unarmed__active, human_attached_gun__attachedGunEid,
                        human_weap__jumpDeviation, human_weap__changePosDeviationCanAim, human_weap__changePosDeviationCanNotAim,
                        human_phys__jumpEndTime, human_phys__afterJumpDelay, human_phys__isInAirLong)
