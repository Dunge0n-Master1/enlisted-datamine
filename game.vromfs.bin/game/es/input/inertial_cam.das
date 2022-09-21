require ecs
require math
require math.base
require Plane
require EnlistedPlane
require EnlistedCamera
require DagorMath
require DagorMathUtils
require DagorSystem
require game.utils.hero

let
  LOCAL_ACCEL_IMMEDIATE = 0.1f
  LOCAL_W_FACTOR = -2.0f
  IMMEDIATE_VISCOSITY = 0.15f
  IMMEDIATE_TO_POS_VISC = 0.15f

[es(tag=input, on_appear, on_event=EventOnSeatOwnersChanged, REQUIRE=plane_input)]
def plane_inertial_cam_update_head_pos(evt : Event;
                                       vehicle_seats__seatEids : EidList;
                                       var plane_inertial_cam__headPos : float3&)
  let eid = get_controlled_hero()
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__cameraPos : float3;
                              seat__ownerEid : EntityId)
      if eid == seat__ownerEid
        plane_inertial_cam__headPos = seat__cameraPos

def apply_cam_angles(vec : float3; angles : float2)
  var res = vec
  query(get_cur_cam_entity()) <| $ [es] (transform : float3x4)
    var rotTm : float3x4
    let up = transform[1]
    make_tm(up, angles.x, rotTm)
    res = rotTm * vec
    let side = transform[0]
    make_tm(side, angles.y, rotTm)
    res = rotTm * vec
  return res

[es(tag=input, before=before_camera_sync, REQUIRE=plane_input)]
def plane_inertial_cam_update(info : UpdateStageInfoAct;
                              plane_net_phys : PlaneActor;
                              transform : float3x4;
                              camera__zoomPos : float;
                              plane_inertial_cam__headPos : float3;
                              plane_inertial_cam__cameraFpsPhysMult : float;
                              plane_inertial_cam__accelAdaptationVisc : float;
                              plane_inertial_cam__headAccelPosRange : float;
                              plane_inertial_cam__headAccelRotScale : float3;
                              plane_inertial_cam__headAccelRotGravScale : float2;
                              plane_inertial_cam__headAccelRotLimits : float3;
                              plane_inertial_cam__immediateToRotVisc : float;
                              plane_inertial_cam__headAccelScale : float3;
                              plane_inertial_cam__headMoveLimits : float3;
                              plane_inertial_cam__headMoveCustomLimits : float4;
                              var plane_inertial_cam__headAccelPos : float3&;
                              var plane_inertial_cam__headAccelPos2 : float3&;
                              var plane_inertial_cam__headImmAccelPos2 : float3&;
                              var plane_inertial_cam__headAccelRot : float3&;
                              var plane_inertial_cam__lastAccel : float3&;
                              var plane_inertial_cam__headShakePos : float3&;
                              var camera__look_at : DPoint3&;
                              var camera__lookDir : float3&)
  let zoom = camera__zoomPos
  let localW = LOCAL_W_FACTOR * cross(plane_inertial_cam__headPos, float3(plane_net_phys.phys.currentState.omega))
  var finalAccel = float3(plane_net_phys.phys.localAccel) + localW
  plane_inertial_cam__lastAccel = approach(plane_inertial_cam__lastAccel, finalAccel, info.dt, plane_inertial_cam__accelAdaptationVisc)
  finalAccel -= plane_inertial_cam__lastAccel
  let localAccel = float3(
    -cvt(finalAccel.x, -10.0, 10.0, -plane_inertial_cam__headAccelPosRange, plane_inertial_cam__headAccelPosRange),
    -cvt(finalAccel.y, -14.0, 14.0, -plane_inertial_cam__headAccelPosRange, plane_inertial_cam__headAccelPosRange),
    -cvt(finalAccel.z, -10.0, 10.0, -plane_inertial_cam__headAccelPosRange, plane_inertial_cam__headAccelPosRange))

  plane_inertial_cam__headAccelPos2.x = approach(plane_inertial_cam__headAccelPos2.x, localAccel.x, info.dt, 0.8f)
  plane_inertial_cam__headAccelPos2.y = approach(plane_inertial_cam__headAccelPos2.y, localAccel.y, info.dt, 0.8f)
  plane_inertial_cam__headAccelPos2.z = approach(plane_inertial_cam__headAccelPos2.z, localAccel.z, info.dt, 0.8f)

  plane_inertial_cam__headImmAccelPos2 = approach(plane_inertial_cam__headImmAccelPos2, localAccel, info.dt, IMMEDIATE_VISCOSITY)

  plane_inertial_cam__headAccelPos = lerp(
    approach(plane_inertial_cam__headAccelPos, plane_inertial_cam__headAccelPos2, info.dt, 0.35f),
    approach(plane_inertial_cam__headAccelPos, plane_inertial_cam__headImmAccelPos2, info.dt, IMMEDIATE_TO_POS_VISC),
    float3(LOCAL_ACCEL_IMMEDIATE))

  let stabilisationMult = max(get_float(get_controlled_hero(), "entity_mods__pilotHeadStabilisationMult") ?? 1.0, 0.0)
  let zoomMult = cvt(zoom, 0.f, 0.5f, 1.2f, 1.f) * cvt(zoom, 0.5f, 1.f, 1.f, 0.5f)
  let isOnGround = plane_net_phys.phys.Gears.onSurface // TODO: stub to remove camera yanking. Real problem is somewhere in physics
  let physMult = isOnGround ? 0.0 : zoomMult * plane_inertial_cam__cameraFpsPhysMult * stabilisationMult
  let curAccel = float3(plane_net_phys.phys.localAccel) - plane_net_phys.phys.currentState.appliedExternalForce / plane_net_phys.phys.mass
  var immediateRotPos = float3(
    plane_inertial_cam__headAccelRotScale.x * float(plane_net_phys.phys.currentState.omega.y) * physMult,
    (-plane_inertial_cam__headAccelRotScale.y * float(plane_net_phys.phys.currentState.omega.z) - plane_inertial_cam__headAccelRotGravScale.x * curAccel.x) * physMult,
    (plane_inertial_cam__headAccelRotScale.z * float(plane_net_phys.phys.currentState.omega.x) - plane_inertial_cam__headAccelRotGravScale.y * curAccel.z) * physMult)
  if abs(immediateRotPos.x) > plane_inertial_cam__headAccelRotLimits.x
    immediateRotPos.x = sign(immediateRotPos.x) * min(pow(abs(immediateRotPos.x) / plane_inertial_cam__headAccelRotLimits.x, 0.3f), 2.f) * plane_inertial_cam__headAccelRotLimits.x
  if abs(immediateRotPos.y) > plane_inertial_cam__headAccelRotLimits.y
    immediateRotPos.y = sign(immediateRotPos.y) * min(pow(abs(immediateRotPos.y) / plane_inertial_cam__headAccelRotLimits.y, 0.3f), 2.f) * plane_inertial_cam__headAccelRotLimits.y
  if abs(immediateRotPos.z) > plane_inertial_cam__headAccelRotLimits.z
    immediateRotPos.z = sign(immediateRotPos.z) * min(pow(abs(immediateRotPos.z) / plane_inertial_cam__headAccelRotLimits.z, 0.3f), 2.f) * plane_inertial_cam__headAccelRotLimits.z
  plane_inertial_cam__headAccelRot = approach(plane_inertial_cam__headAccelRot, immediateRotPos, info.dt, plane_inertial_cam__immediateToRotVisc)

  plane_inertial_cam__headShakePos += plane_inertial_cam__headAccelPos

  let headMoveScale = cvt(zoom, 0.f, 1.f, 1.f, 0.1f) * stabilisationMult

  var headMovePos = float3(
    plane_inertial_cam__headAccelScale.x * plane_inertial_cam__headShakePos.x * headMoveScale,
    plane_inertial_cam__headAccelScale.y * plane_inertial_cam__headShakePos.y * headMoveScale,
    plane_inertial_cam__headAccelScale.z * plane_inertial_cam__headShakePos.z * headMoveScale)

  headMovePos.x /= plane_inertial_cam__headMoveLimits.x
  headMovePos.y = clamp(headMovePos.y, plane_inertial_cam__headMoveCustomLimits.z, plane_inertial_cam__headMoveCustomLimits.w) / plane_inertial_cam__headMoveLimits.y
  headMovePos.z = clamp(headMovePos.z, plane_inertial_cam__headMoveCustomLimits.x, plane_inertial_cam__headMoveCustomLimits.y) / plane_inertial_cam__headMoveLimits.z

  headMovePos.x = max(headMovePos.x, 0.0f) // do not move head backward

  if length(headMovePos) > 1.0f
    headMovePos = normalize(headMovePos)

  headMovePos.x *= plane_inertial_cam__headMoveLimits.x
  headMovePos.y = clamp(headMovePos.y, plane_inertial_cam__headMoveCustomLimits.z, plane_inertial_cam__headMoveCustomLimits.w) * plane_inertial_cam__headMoveLimits.y
  headMovePos.z = clamp(headMovePos.z, plane_inertial_cam__headMoveCustomLimits.x, plane_inertial_cam__headMoveCustomLimits.y) * plane_inertial_cam__headMoveLimits.z

  //logerr("headPos={plane_inertial_cam__headPos}, headAcc={plane_inertial_cam__headAccelRot.xy}, headMove={headMovePos}")

  if (info.dt > 0.f)
    camera__lookDir = apply_cam_angles(camera__lookDir, plane_inertial_cam__headAccelRot.xy)
  let pos = transform[3] + headMovePos
  camera__look_at.x = double(pos.x)
  camera__look_at.y = double(pos.y)
  camera__look_at.z = double(pos.z)

[es(tag=input, after=plane_inertial_cam_update, after=turret_update_turret_aim_point, before=plane_target_forestall, REQUIRE=plane_input)]
def plane_inertial_cam_update_aim_pos(info : UpdateStageInfoAct;
                                      transform : float3x4;
                                      plane_inertial_cam__headAccelRot : float3;
                                      isTurretAimPosValid : bool;
                                      var turretAimPos : float3&)
  if isTurretAimPosValid
    let dir = turretAimPos - transform[3]
    turretAimPos = transform[3] + apply_cam_angles(dir, -plane_inertial_cam__headAccelRot.xy)
