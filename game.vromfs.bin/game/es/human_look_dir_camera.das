require ecs
require EnlistedActor
require EnlistedHuman
require HumanPhys
require math
require math.base
require math.ang
require DagorMath
require DagorMathUtils
require AnimV20
require app
require replay

[es(after=after_net_phys_sync, REQUIRE=watchedByPlr)]
def human_look_dir_camera_es(
                             info : UpdateStageInfoAct;
                             isCameraTarget : bool;
                             human_net_phys : HumanActor;
                             camera__gunAimOffset : float2;
                             var camera__shootOffset : float2&;
                             var camera__prevLookDir : float3&;
                             var camera__lookDir : float3&;
                             camera__shootOffsetTau : float = 0.05f;
                             isAlive : bool = true;
                             death_cam__killer : EntityId = INVALID_ENTITY_ID)

  if !isCameraTarget
    return

  camera__prevLookDir = camera__lookDir

  if isAlive || !death_cam__killer
    assume ct = human_net_phys.phys.producedCT
    let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)

    var ang : float2
    if (int(human_net_phys.role) & int(RoleFlags URF_LOCAL_CONTROL)) != 0
      ang = dir_to_angles(ct.wishLookDir)
    else
      let lerpValue = lerp(human_net_phys.phys.previousState.headDir, human_net_phys.phys.currentState.headDir, float3(interpK))
      ang = dir_to_angles(lerpValue)

    var aimOffs = lerp(human_net_phys.phys.previousState.gunAimOffset, human_net_phys.phys.currentState.gunAimOffset, float2(interpK))
    aimOffs += camera__gunAimOffset

    camera__shootOffset = approach(camera__shootOffset, aimOffs, info.dt, camera__shootOffsetTau)
    ang += camera__shootOffset

    ang.y = clamp(ang.y, -SAFE_HALF_PI, SAFE_HALF_PI)
    camera__lookDir = angles_to_dir(ang)

[es(tag=render, REQUIRE=hero, after=human_look_dir_camera_es, before=before_camera_sync)]
def human_aiming_vertical_limit_es(info : UpdateStageInfoAct;
                                   var human_input__aimAngle : float2&;
                                   human_net_phys : HumanActor;
                                   camera__aimingClampTau : float = 0.1)
  assume phys = human_net_phys.phys
  if !(phys |> human_phys_isAiming())
    return

  let interpK = get_phys_interpk_clamped(phys, info.curTime)
  let interpQuat = slerp(phys.previousState.location.O.quat, phys.currentState.location.O.quat, interpK)
  let aimVertAngle = phys |> human_phys_clampVertAimAngle(human_input__aimAngle.y, interpQuat)
  human_input__aimAngle.y = approach(human_input__aimAngle.y, aimVertAngle, info.dt, camera__aimingClampTau)

[es(after=human_look_dir_camera_es, REQUIRE=watchedByPlr, REQUIRE=deadEntity)]
def human_look_dir_dead_camera_es(info : UpdateStageInfoAct;
                                  eid : EntityId;
                                  transform : float3x4&;
                                  death_cam__killer : EntityId;
                                  death_cam__followTime : float;
                                  deatch_cam__viscosity : float2;
                                  var death_cam__startedAt : float&;
                                  var camera__lookDir : float3&)
  if death_cam__killer == eid
    return
  let killerTm = get_TMatrix(death_cam__killer, "transform")
  if killerTm != null
    if death_cam__startedAt < 0.0
      death_cam__startedAt = info.curTime
    if info.curTime > death_cam__startedAt + death_cam__followTime
      return

    let wishLookDir = normalize((*killerTm)[3] - transform[3])
    let viscosityPercent = cvt(info.curTime, death_cam__startedAt, death_cam__startedAt + death_cam__followTime, 0.0, 1.0)
    let viscosity = deatch_cam__viscosity[0] + deatch_cam__viscosity[1] * viscosityPercent * viscosityPercent
    camera__lookDir = approach(camera__lookDir, wishLookDir, info.dt, viscosity)

[es(after=human_look_dir_camera_es, REQUIRE=watchedByPlr)]
def human_look_dir_camera_in_vehicle_es(info : UpdateStageInfoAct; isInVehicle, isAlive : bool; human_net_phys : HumanActor; var camera__lookDir : float3&)

  if !isInVehicle || !isAlive || is_replay_playing()
    return

  assume ct = human_net_phys.phys.producedCT
  var ang = dir_to_angles(ct.wishLookDir)
  ang.y = clamp(ang.y, -SAFE_HALF_PI, SAFE_HALF_PI)
  camera__lookDir = angles_to_dir(ang)