require ecs
require game.es.camera_common
require common_shooter.es.human_weap_common
require math.base
require HumanPhys
require EnlistedHuman
require EnlistedWeapon
require DagorMath
require DagorMathUtils
require DagorSystem
require Gun
require Grid
require GridCollision
require Dacoll
require CollRes
require AnimV20


def apply_gun_angle_offsets(phys : HumanPhys; at_time : float; var angles : float2&)
  assume prevState = phys.previousState
  assume curState  = phys.currentState
  let prevOffset = prevState.breathOffset + prevState.handsShakeOffset + prevState.gunAimOffset
  let curOffset = curState.breathOffset + curState.handsShakeOffset + curState.gunAimOffset
  let interpK = get_phys_interpk_clamped(phys, at_time)

  angles += lerp(prevOffset, curOffset, float2(interpK))
  let interpQuat = slerp(prevState.location.O.quat, curState.location.O.quat, interpK)
  angles.y = phys |> human_phys_clampVertAimAngle(angles.y, interpQuat)


def do_gun_traceray(from : float3; dir : float3; var t : float&; ray_mat_id : int; ignore_human_eid : EntityId)
  var retEid = INVALID_ENTITY_ID
  var pmid : int
  var norm : float3
  using() <| $(var desc : RendInstDesc#)
    traceray_normalized(from, dir, t, pmid, norm, 127, desc, ray_mat_id)
  using() <| $(var intersections : IntersectedEntities#)
    trace_entities_in_grid(ecs_hash("humans"), from, dir, t, ignore_human_eid, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), from, dir, t, ignore_human_eid, intersections, SortIntersections YES)
    for isect in intersections
      if get_bool(isect.eid, "animchar__visible") ?? true
        retEid = isect.eid
        break
  return retEid


[es(after=human_phys_es, before=after_guns_update_sync, REQUIRE=(human_input, human_weap))]
def human_weap_update_es(info : UpdateStageInfoAct;
                         eid : EntityId;
                         human_weap__gunAngleTau : float;
                         isInVehicle : bool;
                         humap_weap__useGrenadeInVehicle : bool = false;
                         human_weap__lockedGrenadeThrowingCounter : int = 0;
                         human_weap__mortarMode : bool = false;
                         isDowned : bool = false;
                         isAlive : bool = true;
                         entity_mods__shotDeviationMult : float = 1.0;
                         entity_mods__rotationShotSpreadDecrMult : float = 1.0;
                         entity_mods__aimingAfterFireMult : float = 1.0;
                         entity_mods__boltActionMult : float = 1.0;
                         entity_mods__deviationBufferSizeMult : float = 1.0;
                         human_use_object__selectedObject : EntityId? = null;
                         entity_mods__shotDeviationAdd : float = 0.0;
                         human_weap__fastThrowExclusive : bool = true;
                         human_weap__maxParallaxDeviation : float = 10.0;
                         human_weap__extraGunSpeedOnJump : float = 0.0;
                         human_unarmed__active : bool = false;
                         human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                         var human_net_phys : HumanActor;
                         var transform : float3x4;
                         var human_weap__gunEids : EidList;
                         var human_weap__throwMode : bool&;
                         var human_weap__prevGunAngles : float2&;
                         var human_weap__gunAngleSpeed : float2&;
                         var human_weap__traceIntersectedEid : EntityId&;
                         var human_weap__tracerayLen : float&)
  if !isAlive || isDowned || human_net_phys.phys.currentState |> human_phys_state_attachedToLadder
    return

  let dt = info.dt
  let atTime = info.curTime
  let isForReal = true
  let wishGunDir = human_net_phys.phys.producedCT.wishShootDir
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
    apply_gun_angle_offsets(phys, atTime, gunAngles)
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
    query(gunEid) <| $ [es(REQUIRE_NOT=mortar)] (gun__aimRayMatId : int = -1; gun : Gun)
      let camPos = get_cam_pos()
      human_weap__tracerayLen = 100.0
      human_weap__traceIntersectedEid = do_gun_traceray(camPos, gunDir, human_weap__tracerayLen, gun__aimRayMatId, eid)
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

  let updCtx = [[GunUpdateCtx
    dt=dt,
    atTime=atTime,
    isForReal=isForReal,
    eid=eid,
    isDowned=isDowned,
    isThrowingAllowed=human_weap__lockedGrenadeThrowingCounter == 0 && (humap_weap__useGrenadeInVehicle || !isInVehicle),
    shotDeviationMult=entity_mods__shotDeviationMult,
    rotationShotSpreadDecrMult=entity_mods__rotationShotSpreadDecrMult,
    aimingAfterFireMult=entity_mods__aimingAfterFireMult,
    boltActionMult=entity_mods__boltActionMult,
    shotDeviationAdd=entity_mods__shotDeviationAdd,
    fastThrowExclusive=human_weap__fastThrowExclusive,
    deviationBufferSizeMult=entity_mods__deviationBufferSizeMult]]

  human_weap_gun_update(human_net_phys, human_weap__gunEids, human_weap__throwMode,
                        updCtx, transform, gunDir, gunShootDir, transform,
                        human_net_phys.phys.producedCT, human_use_object__selectedObject,
                        human_unarmed__active, human_attached_gun__attachedGunEid)