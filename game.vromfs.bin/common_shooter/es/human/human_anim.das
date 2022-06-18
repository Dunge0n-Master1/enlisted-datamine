require ecs
require app
require AnimV20
require math.base
require EnlistedHumanAnim
require EnlistedHuman
require EnlistedActor
require PhysVars
require PhysDecl
require HumanPhys
require HumanAnim
require DagorMath
require EnlistedWeapon

def private calc_head_pitch_yaw(state : HumanPhysState)
  let localGunDir = inverse(state.location.O.quat) * state.gunDir
  let localHeadDir = inverse(state.location.O.quat) * state.headDir
  let yawPitch = float2(-atan2(localGunDir.z, localGunDir.x), atan2(localGunDir.y, length(localGunDir.xz)))
  return float2(-atan2(localHeadDir.z, localHeadDir.x) - yawPitch.x,
                 atan2(localHeadDir.y, length(localHeadDir.xz)) - yawPitch.y)

def calc_shoot_anims(actor : HumanActor;
                     eid : EntityId;
                     at_time : float;
                     tm : float3x4;
                     head_additional_roll : float;
                     head_additional_pitch : float;
                     head_additional_yaw : float;
                     var pitch : float&;
                     var head_roll : float&;
                     var head_pitch : float&;
                     var head_yaw : float&)
  assume phys = actor.phys
  let interpK = get_phys_interpk_clamped(phys, at_time)

  let prevHead = calc_head_pitch_yaw(phys.previousState)
  let curHead = calc_head_pitch_yaw(phys.currentState)
  let prevGun = dir_to_quat(phys.previousState.gunDir)
  let curGun = dir_to_quat(phys.currentState.gunDir)
  var interpGun = slerp(prevGun, curGun, interpK)
  let gun = get_human_gun(eid)
  var shootTm : float3x4
  make_tm(interpGun, shootTm)
  let requiredNetRole = uint(RoleFlags URF_LOCAL_CONTROL)
  if gun != null && (uint(actor.role) & requiredNetRole) != 0u
    human_gun_get_shoot_tm(*gun, phys, at_time, shootTm)
    interpGun = quat(shootTm)

  pitch = atan2(dot(tm[1], shootTm[0]), dot(tm[0], shootTm[0]))
  head_roll = clamp(deg_to_rad(head_additional_roll), deg_to_rad(-30.0), deg_to_rad(30.0))
  head_yaw = clamp(lerp(prevHead.x, curHead.x, interpK) + deg_to_rad(head_additional_yaw), deg_to_rad(-45.0), deg_to_rad(45.0))
  head_pitch = clamp(lerp(prevHead.y, curHead.y, interpK) + deg_to_rad(head_additional_pitch), deg_to_rad(-70.0), deg_to_rad(60.0))


[es(REQUIRE_NOT=animchar__actOnDemand, no_order)]
def human_anim_es(info : UpdateStageInfoAct;
                  ragdoll : PhysRagdoll?;
                  human_anim__climbHeights : Array;
                  dm_parts__hitPartsAnimationId : Array?;
                  human_net_phys__climbToPos : float3 = float3();
                  transform : float3x4;
                  prevLocoQuat : float4 = float4(0.0, 0.0, 0.0, 1.0);
                  human_net_phys : HumanActor;
                  eid : EntityId;
                  isAlive : bool;
                  stunTimer : float;
                  hitpoints__lastHitNodeId : int = -1;
                  human_inventory__entityToUse : EntityId = INVALID_ENTITY_ID;
                  human_inventory__targetToUse : EntityId = INVALID_ENTITY_ID;
                  human_inventory__entityUseStart : float = -1.0;
                  human_inventory__entityUseEnd : float = -1.0;
                  human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                  human_anim__headYawRotVisc : float = 0.2;
                  human_net_phys__isClimbing : bool = false;
                  human_weap__reloadAtTime : float = -1.0;
                  human_weap__reloadStartTime : float = -1.0;
                  human_weap__weapModActivateStartTime : float = -1.0;
                  human_weap__weapModActivateFinishTime : float = -1.0;
                  human_weap__blockAiming : bool = false;
                  human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                  human_ladder__attached : bool = false;
                  isGunner : bool = false;
                  isInVehicle : bool = false;
                  human_weap__throwMode : bool = false;
                  human_weap__radioMode : bool = false;
                  human_weap__mortarMode : bool = false;
                  animchar__scale : float = 1.0;
                  human_anim__airSpeedMult : float = 0.05;
                  human_anim__jumpTransitionTime : float = 2.0;
                  human_anim__jumpVertSpeedTransitionOffset : float = -10.0;
                  human_anim__vertVelVisc : float = 0.2;
                  human_anim__considerFwdStopped : float = 0.1;
                  human_anim__considerFallingCoef : float = 2.0;
                  burning__isPuttingOut : bool = false;
                  burning__animPutOutEnum : int = -1;
                  bipod__enabled : bool = false;
                  human_vehicle_anim__upperId : int = -1;
                  human_vehicle_anim__lowerId : int = -1;
                  human_vehicle_anim__fireReadyUpperId : int = -1;
                  human_vehicle_anim__fireReadyLowerId : int = -1;
                  human_vehicle_anim__maxStandHeight : float = 1.;
                  animchar__updatable : bool;
                  animchar__visible : bool = true;
                  human_head_dir__interpolationSpeed : float;
                  var human_head_dir__prevAdditionalRoll : float&;
                  var human_head_dir__prevAdditionalPitch : float&;
                  var human_head_dir__prevAdditionalYaw : float&;
                  var human_anim : HumanAnimCtx;
                  var phys_vars : PhysVars;
                  var animchar__animSpeed : float&;
                  var human_anim__jumpTimer : float&)
  if !animchar__updatable || !animchar__visible
    return
  var pitch : float;
  var headRoll : float;
  var headPitch : float;
  var headYaw : float;

  var additionalHeadRoll = 0.0
  var additionalHeadPitch = 0.0
  var additionalHeadYaw = 0.0

  query(human_weap__currentGunEid) <| $ [es] (gun__additionalHeadRoll : float = 0.0;
                                              gun__additionalHeadPitch : float = 0.0;
                                              gun__additionalHeadYaw : float = 0.0)
    additionalHeadRoll = lerp(human_head_dir__prevAdditionalRoll, gun__additionalHeadRoll, human_head_dir__interpolationSpeed)
    additionalHeadPitch = lerp(human_head_dir__prevAdditionalPitch, gun__additionalHeadPitch, human_head_dir__interpolationSpeed)
    additionalHeadYaw = lerp(human_head_dir__prevAdditionalYaw, gun__additionalHeadYaw, human_head_dir__interpolationSpeed)
    human_head_dir__prevAdditionalRoll = additionalHeadRoll
    human_head_dir__prevAdditionalPitch = additionalHeadPitch
    human_head_dir__prevAdditionalYaw = additionalHeadYaw

  calc_shoot_anims(human_net_phys, eid, info.curTime, transform,
                   additionalHeadRoll, additionalHeadPitch, additionalHeadYaw,
                   pitch, headRoll, headPitch, headYaw)

  let dt = info.dt
  let curTime = get_sync_time()

  var animHitPartId = 0
  if dm_parts__hitPartsAnimationId != null && hitpoints__lastHitNodeId > -1
    animHitPartId = (hitpoints__lastHitNodeId < length(*dm_parts__hitPartsAnimationId) ?
      get_int((*dm_parts__hitPartsAnimationId)[hitpoints__lastHitNodeId]) ?? 0 : 0)

  let unitTm = transform
  assume phys = human_net_phys.phys

  let interpK = get_phys_interpk_clamped(phys, curTime)
  let walkDir = lerp(phys.previousState.walkDir, phys.currentState.walkDir, float2(interpK))
  let bodyDir = lerp(phys.previousState.bodyOrientDir, phys.currentState.bodyOrientDir, float2(interpK))
  var bodyDir3d = float3(bodyDir.x, 0.0, bodyDir.y)
  let up = unitTm[1]
  bodyDir3d = normalize(bodyDir3d - bodyDir3d * up * up)
  let walkYaw = rad_to_deg(atan2(walkDir.y, walkDir.x))
  let bodyYaw = rad_to_deg(atan2(bodyDir3d.z, bodyDir3d.x))
  let velDelta = lerp(phys.previousState.velocity - phys.previousState.standingVelocity,
                      phys.currentState.velocity - phys.currentState.standingVelocity, float3(interpK))
  var spd = length(velDelta.xz)
  var isClimbing = human_net_phys__isClimbing

  phys_vars |> setVar(human_anim.gunPitchVarId, rad_to_deg(pitch))
  phys_vars |> setVar(human_anim.walkDirVarId, walkYaw + 90.0)
  phys_vars |> setVar(human_anim.bodyDirVarId, bodyYaw + 90.0)

  if phys.currentState.isAiming
    let breathOffset = lerp(phys.previousState.breathOffset, phys.currentState.breathOffset, float2(interpK))
    headYaw += breathOffset.x * 0.9
    headPitch += breathOffset.y * 0.9
    var hd : float
    var att : float
    var bank : float
    let q = quat(prevLocoQuat)
    quat_to_euler(q, hd, att, bank)
    headPitch += att
    headPitch = max(0.0, headPitch)
  phys_vars |> setVar(human_anim.headRollVarId, rad_to_deg(headRoll))
  phys_vars |> setVar(human_anim.headPitchVarId, rad_to_deg(headPitch))
  let prevHeadYawVar = phys_vars |> getVar(human_anim.headYawVarId)
  let newHeadYawVar = approach(prevHeadYawVar, rad_to_deg(headYaw),
                               dt, human_anim__headYawRotVisc)
  phys_vars |> setVar(human_anim.headYawVarId, newHeadYawVar)
  phys_vars |> setVar(human_anim.leanVarId, lerp(phys.previousState.leanPosition, phys.currentState.leanPosition, interpK))
  phys_vars |> setVar(human_anim.standHeightVarId, lerp(phys.previousState.height, phys.currentState.height, interpK))
  phys_vars |> setVar(human_anim.hitPartsSelectedVarId, float(animHitPartId))

  var dir = unitTm[0]
  dir = normalize(dir - dir * up * up)
  let persCourse = rad_to_deg(atan2(dir.z, dir.x))
  phys_vars |> setVar(human_anim.persCourseVarId, persCourse + 90.0)
  let reduceToWalk = abs(norm_s_ang_deg(persCourse - walkYaw)) > 60.0

  let isSwimming = human_phys_state_get_is_swimming(human_net_phys.phys.currentState)
  if (int(human_net_phys.phys.currentState.isInAirHistory) & 1) != 0 && !isSwimming && !isClimbing
    human_anim__jumpTimer += info.dt
    spd *= cvt(human_anim__jumpTimer, 0.0, human_anim__jumpTransitionTime * 0.5, 1.0, human_anim__airSpeedMult)
  else
    human_anim__jumpTimer = 0.0

  let standState = phys.currentState.standState

  let statePos = (bipod__enabled &&
                 standState != HUStandState ESS_CRAWL ? HumanStatePos E_BIPOD :
                 standState == HUStandState ESS_STAND ? HumanStatePos E_STAND :
                 standState == HUStandState ESS_DOWNED ? HumanStatePos E_DOWNED :
                 standState == HUStandState ESS_CROUCH ? HumanStatePos E_CROUCH :
                 standState == HUStandState ESS_CRAWL ? HumanStatePos E_CRAWL :
                 standState == HUStandState ESS_SWIM ? HumanStatePos E_SWIM :
                 standState == HUStandState ESS_SWIM_UNDERWATER ? HumanStatePos E_SWIM_UNDERWATER :  HumanStatePos E_STAND)

  var stateMove = (phys.currentState.moveState == HUMoveState EMS_SPRINT ? HumanStateMove E_SPRINT :
                   phys.currentState.moveState == HUMoveState EMS_WALK ? HumanStateMove E_MOVE :
                   phys.currentState.moveState == HUMoveState EMS_RUN ? !reduceToWalk ? HumanStateMove E_RUN : HumanStateMove E_MOVE :
                   phys.currentState.moveState == HUMoveState EMS_ROTATE_LEFT ? HumanStateMove E_ROTATE_LEFT :
                   phys.currentState.moveState == HUMoveState EMS_ROTATE_RIGHT ? HumanStateMove E_ROTATE_RIGHT :
                   HumanStateMove E_STILL)

  var stateUpperBody = HumanStateUpperBody E_READY
  if human_weap__throwMode
    let effectiveCurSlot = phys.currentState.weapEquipState.effectiveCurSlot
    stateUpperBody = (effectiveCurSlot == HUWeaponSlots EWS_GRENADE ? HumanStateUpperBody E_THROW
                                                                    : HumanStateUpperBody E_FAST_THROW)
  elif phys.currentState.weapEquipState.curState == HUWeaponEquipState EES_EQUIPED
    let reload = (curTime >= human_weap__reloadStartTime &&
                  curTime <= human_weap__reloadAtTime)
    let weapModActivate = (curTime >= human_weap__weapModActivateStartTime &&
                           curTime <= human_weap__weapModActivateFinishTime)
    stateUpperBody = ((reload || weapModActivate) ? HumanStateUpperBody E_RELOAD :
                      human_phys_isAiming(phys) ? HumanStateUpperBody E_AIM : HumanStateUpperBody E_READY)
  elif (phys.currentState.weapEquipState.curState == HUWeaponEquipState EES_HOLSTERING ||
        phys.currentState.weapEquipState.curState == HUWeaponEquipState EES_EQUIPING)
    stateUpperBody = HumanStateUpperBody E_CHANGE

    assume prevState = phys.previousState.weapEquipState
    assume curState = phys.currentState.weapEquipState
    let prevProgress = (prevState.curState == HUWeaponEquipState EES_EQUIPING ? 0.5 : 0.0) + prevState.progress * 0.5
    let curProgress = (curState.curState == HUWeaponEquipState EES_EQUIPING ? 0.5 : 0.0) + curState.progress * 0.5
    let progress = lerp(prevProgress, curProgress, interpK)
    phys_vars |> setVar(human_anim.changeWeaponVarId, 1.0 - abs(1.0 - progress * 2.0))
    phys_vars |> setVar(human_anim.changeDirVarId, (progress <= 0.5 ? -1.0 : 1.0))

  elif phys.currentState.weapEquipState.curState == HUWeaponEquipState EES_DOWN
    let reload = phys_vars |> getVar(human_anim.reloadVarId)
    stateUpperBody = reload > 0.0 ? HumanStateUpperBody E_READY : HumanStateUpperBody E_DOWN

  query(eid) <| $ [es] (human_weap__bulletDeflectionState : Object)
    let startTime = get_float(human_weap__bulletDeflectionState, "startTime") ?? -1.0
    let endTime = get_float(human_weap__bulletDeflectionState, "endTime") ?? -1.0
    if curTime >= startTime && curTime < endTime
      stateUpperBody = HumanStateUpperBody E_DEFLECT
      let deflAngle = get_float(human_weap__bulletDeflectionState, "deflAngle") ?? 0.0
      phys_vars |> setVar(human_anim.deflectionProgressVarId, sqrt(sqrt(cvt(curTime, startTime, endTime, 0.0, 1.0))))
      phys_vars |> setVar(human_anim.deflectionAngleVarId, deflAngle)

  if human_inventory__entityToUse != INVALID_ENTITY_ID && info.curTime < human_inventory__entityUseEnd
    if has(human_inventory__entityToUse, "item__healAnimEnumValue")
      stateUpperBody = HumanStateUpperBody E_HEAL
      query(human_inventory__entityToUse) <| $ [es] (item__healAnimEnumValue : int;
                                                     item__healTargetAnimEnumValue : int)
        let isTarget = human_inventory__targetToUse != INVALID_ENTITY_ID && human_inventory__targetToUse != eid
        let healEnum = (isTarget && item__healTargetAnimEnumValue > -1 ?
                       item__healTargetAnimEnumValue : item__healAnimEnumValue)
        phys_vars |> setVar(human_anim.healItemSelectedVarId, float(healEnum))
    else
      query(human_inventory__entityToUse) <| $ [es(REQUIRE=item__defibrillator)] (defibrillator_anim__firstStageTime : float;
                                                                                  defibrillator_anim__finalStageTime : float)
        if (info.curTime < human_inventory__entityUseStart + defibrillator_anim__firstStageTime)
          stateUpperBody = HumanStateUpperBody E_USE_DEFIBRILLATOR_START
        if (info.curTime > human_inventory__entityUseEnd - defibrillator_anim__finalStageTime)
          stateUpperBody = HumanStateUpperBody E_USE_DEFIBRILLATOR_FINISH

  if burning__isPuttingOut
    stateUpperBody = HumanStateUpperBody E_PUT_OUT_FIRE
    phys_vars |> setVar(human_anim.healItemSelectedVarId, float(burning__animPutOutEnum))

  if human_weap__radioMode
    stateUpperBody = HumanStateUpperBody E_USE_RADIO

  if human_weap__mortarMode
    stateUpperBody = HumanStateUpperBody E_USE_MORTAR

  if isClimbing
    let posHt = human_net_phys__climbToPos.y - unitTm[3].y
    var startPt = float2(0.0, 1.0)
    var endPt = float2(0.0, 1.0)
    for attr in human_anim__climbHeights
      let ht = get_Point2(attr) ?? float2()
      if posHt > ht.x
        startPt = ht
        endPt = ht
      else
        endPt = ht
        break
    let climbProgress = cvt(posHt, startPt.x, endPt.x, startPt.y, endPt.y)
    if climbProgress == 1.0
      isClimbing = false
      stateMove = HumanStateMove E_MOVE
    phys_vars |> setVar(human_anim.climbProgressVarId, climbProgress)

  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                vehicle_seats__enumVarId : int = -1)
    if vehicle_seats__enumVarId >= 0
      phys_vars |> setVar(human_anim.vehicleSelectedVarId, float(vehicle_seats__enumVarId))
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerEid : EntityId;
                                seat__enumVarId : int)
        if eid == seat__ownerEid && seat__enumVarId >= 0
          phys_vars |> setVar(human_anim.seatTypeVarId, float(seat__enumVarId))

  var state_flags = uint(HumanAnimStateFlags None)
  if ragdoll == null && !isAlive
    state_flags |= uint(HumanAnimStateFlags Dead)
  if stunTimer >= 0.0
    state_flags |= uint(HumanAnimStateFlags Attacked)
  if isGunner
    state_flags |= uint(HumanAnimStateFlags Gunner)
  if isClimbing
    state_flags |= uint(HumanAnimStateFlags Climbing)
  if human_ladder__attached
    state_flags |= uint(HumanAnimStateFlags Ladder)

  // Jumping and falling animation
  let moveVThres = 0.01
  var moveV = float3(phys.currentState.location.P - phys.previousState.location.P)
  let moveVlen = length(moveV)
  moveV = moveVlen > moveVThres ? moveV * safeinv(moveVlen) : float3()
  let fwdV = phys.currentState.location.fwd
  let fwdStopped = dot(moveV, fwdV) < human_anim__considerFwdStopped
  let isOnGround = (uint(phys.currentState.states) & uint(StateFlag ST_ON_GROUND)) != 0u
  let isClimbingCurrentState = human_phys_state_get_isClimbing(phys.currentState)
  let inJumping = (!isOnGround && !isClimbingCurrentState &&
                  (statePos != HumanStatePos E_SWIM && statePos != HumanStatePos E_SWIM_UNDERWATER))
  let inLongJump = human_anim__jumpTimer > human_anim__jumpTransitionTime
  let walkSpeed = phys |> human_phys_getWalkSpeed(HUStandState ESS_STAND, HUMoveState EMS_WALK)
  let isFalling = phys.currentState.velocity.y < -walkSpeed * human_anim__considerFallingCoef
  let jumpFromStand = inJumping && fwdStopped && !isFalling
  let vertSpeed = phys.currentState.velocity.y + (jumpFromStand ? 0.0 :
                                                  cvt(human_anim__jumpTimer,
                                                      human_anim__jumpTransitionTime,
                                                      human_anim__jumpTransitionTime * 2.0,
                                                      human_anim__jumpVertSpeedTransitionOffset,
                                                      0.0))
  let prevVertSpeedVar = phys_vars |> getVar(human_anim.vertSpeedVarId)
  let newVertSpeedVar = approach(prevVertSpeedVar, vertSpeed, dt, human_anim__vertVelVisc)
  phys_vars |> setVar(human_anim.vertSpeedVarId, newVertSpeedVar)
  let stateJump = (jumpFromStand || inLongJump) ? StateJump E_FROM_STAND : inJumping ? StateJump E_NOT_JUMP : StateJump E_NOT_JUMP

  var state = HumanAnimStateResult(-1, -1)
  if isInVehicle
    state = (!human_weap__blockAiming && phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM) ?
      HumanAnimStateResult(human_vehicle_anim__fireReadyUpperId, human_vehicle_anim__fireReadyLowerId) :
      HumanAnimStateResult(human_vehicle_anim__upperId, human_vehicle_anim__lowerId))
    if phys.currentState.height > human_vehicle_anim__maxStandHeight
      phys_vars |> setVar(human_anim.standHeightVarId, human_vehicle_anim__maxStandHeight)
  else
    state = human_anim.animState |> updateState(statePos, stateMove, stateJump, stateUpperBody, state_flags)

  send_change_anim_state_event(eid, "lower", ecs_hash("lower"), state.lower)
  send_change_anim_state_event(eid, "upper", ecs_hash("upper"), state.upper)
  animchar__animSpeed = spd * safeinv(animchar__scale)
