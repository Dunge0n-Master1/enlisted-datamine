require ecs
require ecs.common
require app
require math.base
require game.es.input.input_events
require game.es.input.input_common
require game.es.events
require game.es.action_common
require game.events_game
require player
require DagorMath
require DagorMathUtils
require DagorInput
require DagorDriver3D
require TouchInput
require HumanPhys
require EnlistedHuman
require EnlistedInputControls
require EnlistedCamera

let DEFAULT_VERT_LOOK_ANGLE_LIMIT_DEG = float2(-72.0, 87.0)
let DEFAULT_VERT_LOOK_ANGLE_LIMIT_RAD = deg_to_rad(DEFAULT_VERT_LOOK_ANGLE_LIMIT_DEG)

let DEFAULT_RESET_SPRINT_MOVEMENT_THRESHOLD = 0.7
let DEFAULT_RESET_SPRINT_MOVE_THRESHOLD = -0.1


def is_shoot_dir_blocked(actor : HumanActor)
  let isDowned = actor.phys.currentState |> human_phys_state_get_is_downed()
  let revivingCount = actor.eid |> get_int("hitpoints__revivingCount") ?? 0
  return isDowned && revivingCount > 0


def update_look_dir(var actor : HumanActor&;
                    var aim_angle : float2&;
                    aim_offset : float2;
                    vert_look_angle_limit : float2;
                    persp_wk : float;
                    ax : double = 0.0lf;
                    ay : double = 0.0lf;
                    lx : float = 0.0;
                    ly : float = 0.0)

  let vertLookAngleLimit = float2(max(vert_look_angle_limit.x, -SAFE_HALF_PI),
                                  min(vert_look_angle_limit.y, SAFE_HALF_PI))
  let aimAngleUnbounded = aim_angle + float2(ax, ay) * safeinv(persp_wk)
  aim_angle.x = norm_s_ang(aimAngleUnbounded.x)
  aim_angle.y = clamp(aimAngleUnbounded.y, vertLookAngleLimit.x, vertLookAngleLimit.y)

  var lookAngle = aim_angle + float2(lx, ly)
  lookAngle.y = clamp(lookAngle.y, vertLookAngleLimit.x, vertLookAngleLimit.y)

  let curVertDirection = actor.phys.currentState.vertDirection
  let prevVertDirection = actor.phys.previousState.vertDirection
  let interpK = get_phys_interpk_clamped(actor.phys, get_sync_time())

  let up = float3(0.0, 1.0, 0.0)
  let curRot = quat_rotation_arc(up, curVertDirection)
  let prevRot = quat_rotation_arc(up, prevVertDirection)
  let rot = slerp(prevRot, curRot, interpK)

  if !is_shoot_dir_blocked(actor)
    let angle = aim_angle + aim_offset
    let dir = angles_to_dir(angle)
    actor.phys.producedCT |> human_control_state_set_wish_shoot_dir(rot * dir)
  let lookDir = angles_to_dir(lookAngle)
  actor.phys.producedCT |> human_control_state_set_wish_look_dir(rot * lookDir)


def update_walk_dir(var actor : HumanActor&;
                    move : double = 0.0lf;
                    strafe : double = 0.0lf)
  actor.phys.producedCT |> human_control_state_set_walk_dir(float2(move, -strafe))


def update_movement(dt : float;
                    human_input__aim : int;
                    human_input__aimDelta : int;
                    human_input__look : int;
                    human_input__move : int;
                    human_input__sprint : int;
                    human_input__perspWk : float;
                    human_input__forceLookMode : bool;
                    human_input__blockLookModeCounter : int;
                    aim_offset : float2&;
                    vehicle_input__aim : int const?;
                    isInVehicle : bool;
                    need_update_look_dir : bool = true;
                    need_update_walk_dir : bool = true;
                    look_axis_value_clamp : float2 = float2(0.5, 0.5);
                    vert_look_angle_limit = DEFAULT_VERT_LOOK_ANGLE_LIMIT_RAD;
                    human_input__aimingSensMult : float = 1.0;
                    human_input__resetSprintMovementThreshold : float = DEFAULT_RESET_SPRINT_MOVEMENT_THRESHOLD;
                    human_input__resetSprintMoveThreshold : float = DEFAULT_RESET_SPRINT_MOVE_THRESHOLD;
                    human_input__lookAngleTau : float = 0.;
                    human_vehicle__isShootingPassenger : bool;
                    var actor : HumanActor&;
                    var aim_angle : float2&;
                    var human_input__lookAngle : float2&)

  if need_update_look_dir
    let inputDotAim = vehicle_input__aim != null ? *vehicle_input__aim : human_input__aim
    let asAim = get_analog_stick_action_state(uint16(inputDotAim))
    let asLook = get_analog_stick_action_state(uint16(human_input__look))
    let touchAim = get_stick_value(uint16(human_input__aim))

    var ax = asAim.bActive ? clamp(double(asAim.x + touchAim.x), -1.0lf, 1.0lf) : 0.0lf
    var ay = asAim.bActive ? clamp(double(asAim.y + touchAim.y), -1.0lf, 1.0lf) : 0.0lf

    // Sensitivity multiplier
    var sensMult = 1.0lf
    let isZoomView = actor.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_ZOOM_VIEW)
    let isAim = actor.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM)

    if isZoomView || isAim
      sensMult = double(get_sens_scale().humanAiming * human_input__aimingSensMult)
    elif isInVehicle && !human_vehicle__isShootingPassenger
      sensMult = double(get_sens_scale().vehicleCam)
    elif get_cur_cam_entity() |> get_bool("isTpsView") ?? false
      sensMult = double(get_sens_scale().humanTpsCam)
    else
      sensMult = double(get_sens_scale().humanFpsCam)

    ax *= sensMult
    ay *= sensMult

    // Aim delta
    let asAimDelta = get_analog_stick_action_state(uint16(human_input__aimDelta))
    if asAimDelta.bActive
      ax += double(asAimDelta.x)
      ay += double(asAimDelta.y)

    // Look
    let prevLookAngle = human_input__lookAngle
    var shouldResetLookAngle = false
    if (asLook.bActive || human_input__forceLookMode) && human_input__blockLookModeCounter <= 0
      if actor.phys |> human_phys_isAiming() && !human_input__forceLookMode
        ax += double(asLook.x)
        ay += double(asLook.y)
        shouldResetLookAngle = true
      else
        let lookDelta = human_input__forceLookMode && !asLook.bActive ? float2(ax, ay) : float2(asLook.x, asLook.y)
        // we reset aim move when in forceLookMode, otherwise we will move the gun too
        if human_input__forceLookMode
          ax = 0.0lf
          ay = 0.0lf
        human_input__lookAngle.x = clamp(prevLookAngle.x + lookDelta.x,
                                            -look_axis_value_clamp.x,
                                            look_axis_value_clamp.x)
        human_input__lookAngle.y = clamp(prevLookAngle.y + lookDelta.y,
                                            -look_axis_value_clamp.y,
                                            look_axis_value_clamp.y)
    else
      shouldResetLookAngle = true
    if shouldResetLookAngle
      human_input__lookAngle.x = approach(prevLookAngle.x, 0., dt, human_input__lookAngleTau)
      human_input__lookAngle.y = approach(prevLookAngle.y, 0., dt, human_input__lookAngleTau)
    update_look_dir(actor,
                    aim_angle,
                    aim_offset,
                    vert_look_angle_limit,
                    human_input__perspWk,
                    ax * double(PI),
                    ay * double(PI),
                    human_input__lookAngle.x * PI,
                    human_input__lookAngle.y * PI)

  if need_update_look_dir && !need_update_walk_dir
    return

  var strafe = 0.0lf
  var move = 0.0lf
  if need_update_walk_dir
    let asMove = get_analog_stick_action_state(uint16(human_input__move))
    let touchMove = get_stick_value(uint16(human_input__move))
    move = clamp(double(asMove.y + touchMove.y), -1.0lf, 1.0lf)
    strafe = clamp(double(asMove.x + touchMove.x), -1.0lf, 1.0lf)

  update_walk_dir(actor, move, strafe)

  if (abs(move) + abs(strafe) < double(human_input__resetSprintMovementThreshold) ||
      move < double(human_input__resetSprintMoveThreshold))
    reset_digital_action_sticky_toggle(uint16(human_input__sprint))


def apply_human_input_tm(human_input__perspWk : float;
                         fwd : float3&;
                         vert_look_angle_limit_rad : float2;
                         var actor : HumanActor&;
                         var aim_angle : float2&)
  aim_angle = dir_to_angles(fwd)
  update_look_dir(actor,
                  aim_angle,
                  float2(0, 0),
                  vert_look_angle_limit_rad,
                  human_input__perspWk)
  update_walk_dir(actor)


def fix_changed_hero_input(dt : float;
                           var human_input__hasValidState : bool&;
                           var human_net_phys : HumanActor&;
                           var aim_angle : float2&;
                           var human_input__lookAngle : float2&;
                           human_input__lookAngleTau : float;
                           human_input__aim : int;
                           human_input__aimDelta : int;
                           human_input__look : int;
                           human_input__move : int;
                           human_input__sprint : int;
                           human_input__perspWk : float;
                           human_input__forceLookMode : bool;
                           human_input__blockLookModeCounter : int;
                           human_vehicle__isShootingPassenger : bool;
                           aim_offset : float2&;
                           vehicle_input__aim : int const?;
                           isInVehicle : bool;
                           human_input__resetSprintMovementThreshold : float = DEFAULT_RESET_SPRINT_MOVEMENT_THRESHOLD;
                           human_input__resetSprintMoveThreshold : float = DEFAULT_RESET_SPRINT_MOVE_THRESHOLD)
  assume phys = human_net_phys.phys
  assume ct = phys.producedCT
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_JUMP, false)
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, false)
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, false)
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_RELOAD, false)
  ct |> human_control_state_set_throw_state(false, HumanControlThrowSlot HCTS_SLOT0)
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_THROW_BACK, false)
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_MELEE, false)

  let isCrouch = phys.previousState.isCrouch
  let isCrawl = phys.previousState.isCrawl
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, isCrouch)
  ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, isCrawl)

  update_movement(dt, human_input__aim, human_input__aimDelta,
                  human_input__look, human_input__move,
                  human_input__sprint, human_input__perspWk,
                  human_input__forceLookMode,
                  human_input__blockLookModeCounter,
                  aim_offset, vehicle_input__aim, isInVehicle,
                  true, true, float2(0.5, 0.5),
                  DEFAULT_VERT_LOOK_ANGLE_LIMIT_RAD, 1.0,
                  human_input__resetSprintMovementThreshold,
                  human_input__lookAngleTau,
                  human_input__resetSprintMoveThreshold,
                  human_vehicle__isShootingPassenger,
                  human_net_phys, aim_angle,
                  human_input__lookAngle)
  human_input__hasValidState = true


def set_ct_controlbit(var human_net_phys : HumanActor&;
                      state : HumanPhysControlType;
                      action : uint16)
  if is_action_active(action)
    let value = get_digital_action_state(action).bState || is_button_pressed(action)
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(state, value)


[es(tag=input, on_appear, track=human_anim__vehicleSelected, before=human_input_es)]
def human_input_init_follow_vehicle_es(evt : Event;
                                       human_anim__vehicleSelected : EntityId;
                                       var human_input__lastVehicleAngle : float&;
                                       var human_input__lastVehicleAngleDelta : float&)
  human_input__lastVehicleAngleDelta = 0.0
  human_input__lastVehicleAngle = 0.0
  query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4)
    human_input__lastVehicleAngle = dir_to_angles(transform[0]).x

def input_melee(cur_time : float;
                is_gamepad : bool;
                human_input__melee : int;
                human_input__canShoot : bool;
                main_attack_is_melee : bool;
                input_shoot : int;
                is_sprinting : bool;
                human_melee_charge__targetFound : bool;
                human_melee_charge__longPressTime : float;
                human_input__wishMelee : bool;
                var phys : HumanPhys&;
                var human_melee_charge__activateAtTime : float&;
                var human_input__meleeInputStartTime : float&;
                var human_melee_charge__lastMeleeButtonState : bool&;
                var human_melee_charge__forceEnabled : bool&)
  var isMeleeButtonPressed = get_digital_action_state(uint16(human_input__melee)).bState || is_button_pressed(uint16(human_input__melee))
  if main_attack_is_melee && is_action_active(uint16(input_shoot)) && human_input__canShoot
    isMeleeButtonPressed ||= get_digital_action_state(uint16(input_shoot)).bState || is_button_pressed(uint16(input_shoot))

  let isMeleeChargingInput = (isMeleeButtonPressed || human_melee_charge__forceEnabled) && is_sprinting && !human_input__wishMelee
  if isMeleeChargingInput && human_melee_charge__activateAtTime < 0.
    human_melee_charge__activateAtTime = cur_time + human_melee_charge__longPressTime
  elif !isMeleeChargingInput
    human_melee_charge__activateAtTime = -1.0

  let isMeleeCharge = human_melee_charge__activateAtTime > 0.0 && cur_time > human_melee_charge__activateAtTime

  if is_gamepad && isMeleeCharge
    if isMeleeButtonPressed && !human_melee_charge__lastMeleeButtonState
      human_melee_charge__forceEnabled = false
  else
    human_melee_charge__forceEnabled = false

  human_melee_charge__lastMeleeButtonState = isMeleeButtonPressed
  if isMeleeCharge
    human_melee_charge__forceEnabled = is_gamepad
    human_input__meleeInputStartTime = -1.0
    phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_MELEE, true)
    phys.producedCT |> human_control_state_setAltAttackState(true)
  else
    phys.producedCT |> human_control_state_setAltAttackState(false)
    phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_MELEE, human_input__wishMelee)

  if human_melee_charge__targetFound && isMeleeCharge
    phys.producedCT |> human_control_state_setAltAttackState(false)
    phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_MELEE, false)

[es(tag=input)]
def human_input_es(info : UpdateStageUpdateInput;
                   eid : ecs::EntityId;
                   human_input__aim : int;
                   human_input__aimDelta : int;
                   human_input__look : int;
                   human_input__move : int;
                   human_input__sprint : int;
                   human_input__leanX : int;
                   human_input__aim1 : int;
                   human_input__aim2 : int;
                   human_input__zoom : int;
                   human_input__holdBreath : int;
                   human_input__melee : int;
                   isInVehicle : bool;
                   human_input__jump : int;
                   human_input__reload : int;
                   human_input__wishMelee : bool;
                   human_anim__vehicleSelected : ecs::EntityId;
                   human_anim__vehicleFollowDirCoef : float = 1.003;
                   human_input__lastWeaponChangeInput : float;
                   human_input__aimAngleOffset : float2&;
                   human_weap__throwMode : bool;
                   human_input__forceLookMode : bool;
                   human_input__shoot : int = 0;
                   human_weap__currentGunEid : EntityId;
                   human_input__lookDirClamp : float2 = float2(90.f, 90.f);
                   human_input__currentVertLookAngleLimit : float2;
                   human_input__prevVertLookAngleLimit : float2;
                   human_input__aimingSensMult : float = 1.0f;
                   human_input__crawlingReject : bool = true;
                   camera_input__disabled : bool = false;
                   human_input__resetSprintMovementThreshold : float = DEFAULT_RESET_SPRINT_MOVEMENT_THRESHOLD;
                   human_input__resetSprintMoveThreshold : float = DEFAULT_RESET_SPRINT_MOVE_THRESHOLD;
                   human_input__sprintMoveThreshold : float = 0.7;
                   human_input__crawlToAnyTransitionHeight : float = -0.9;
                   human_input__crawlToCrouchTransitionHeight : float = -0.4;
                   human_input__lookAngleTau : float = 0.;
                   human_input__canShoot : bool = true;
                   human_input__forceAim : bool = false;
                   human_input__blockLeaningCounter : int = 0;
                   human_input__blockLookModeCounter : int = 0;
                   human_vehicle__isShootingPassenger : bool = false;
                   human_melee_charge__targetFound : bool = false;
                   human_melee_charge__longPressTime : float = 0.2;
                   isTpsView : bool = false;
                   human_input__followVehicleRotationInFirstPerson : bool = true;
                   var human_melee_charge__forceEnabled : bool&;
                   var human_melee_charge__activateAtTime : float&;
                   var human_input__meleeInputStartTime : float&;
                   var human_melee_charge__lastMeleeButtonState : bool&;
                   var human_input__perspWk : float&;
                   var human_input__hasValidState : bool&;
                   var human_input__standState : int&;
                   var human_input__aimAngle : float2&;
                   var human_input__oldAimAngle : float2&;
                   var human_input__lastShootInput : float&;
                   var human_net_phys : HumanActor&;
                   var human_input__lookAngle : float2&;
                   var human_input__lastVehicleAngle : float&;
                   var human_input__lastVehicleAngleDelta : float&)

  if camera_input__disabled
    return

  assume phys = human_net_phys.phys

  get_Driver3dPerspective() <| $(pers : Driver3dPerspective#)
    human_input__perspWk = pers.wk

  var vehicleInputAim : int const? = null
  var vehicleInputShoot : int const? = null
  var vehicleInputZoomToggle : int const? = null
  var vehicleInputZoom : int const? = null
  if isInVehicle
    query(human_anim__vehicleSelected) <| $ [es] (vehicle_input__aim : int const?;
                                                  vehicle_input__shoot : int const?;
                                                  vehicle_input__zoomToggle : int const?;
                                                  vehicle_input__zoom : int const?;
                                                  transform : float3x4)
      vehicleInputAim = vehicle_input__aim
      vehicleInputShoot = vehicle_input__shoot
      vehicleInputZoomToggle = vehicle_input__zoomToggle
      vehicleInputZoom = vehicle_input__zoom

      human_input__lastVehicleAngleDelta = 0.0
      let vehicleAngle = dir_to_angles(transform[0])
      if human_input__followVehicleRotationInFirstPerson && !isTpsView
        human_input__lastVehicleAngleDelta = angle_diff(human_input__lastVehicleAngle, vehicleAngle.x)
        human_input__lastVehicleAngleDelta *= human_anim__vehicleFollowDirCoef
        human_input__aimAngle.x = norm_s_ang(human_input__aimAngle.x + human_input__lastVehicleAngleDelta)
      human_input__lastVehicleAngle = vehicleAngle.x

  human_input__oldAimAngle = human_input__aimAngle

  if !human_input__hasValidState
    fix_changed_hero_input(info.dt,
                           human_input__hasValidState,
                           human_net_phys,
                           human_input__aimAngle, human_input__lookAngle,
                           human_input__lookAngleTau,
                           human_input__aim, human_input__aimDelta,
                           human_input__look, human_input__move,
                           human_input__sprint, human_input__perspWk,
                           human_input__forceLookMode,
                           human_input__blockLookModeCounter,
                           human_vehicle__isShootingPassenger,
                           human_input__aimAngleOffset,
                           vehicleInputAim, isInVehicle,
                           human_input__resetSprintMovementThreshold,
                           human_input__resetSprintMoveThreshold)

  var shouldUpdateWalkDir = is_action_active(uint16(human_input__move))

  let inputAim1 = human_vehicle__isShootingPassenger ? vehicleInputZoomToggle ?? human_input__aim1 : human_input__aim1
  let inputAim2 = human_vehicle__isShootingPassenger ? vehicleInputZoom ?? human_input__aim2 : human_input__aim2
  let aim1 = (is_action_active(uint16(inputAim1))
             ? (get_digital_action_state(uint16(inputAim1)).bState || is_button_pressed(uint16(inputAim1)))
             : false) || human_input__forceAim
  let aim2 = (is_action_active(uint16(inputAim2))
             ? get_digital_action_state(uint16(inputAim2)).bState
             : false) || human_input__forceAim
  var aim = aim1 || aim2

  var crawl = (human_input__standState == int(HumanPhysControlType HCT_CRAWL))
  var crouch = (human_input__standState == int(HumanPhysControlType HCT_CROUCH))

  // Min height of a soldier at which allow him to move when changing states to aim.
  let crawlToAnyTransitionHeight = human_input__crawlToAnyTransitionHeight
  let crawlToCrouchTransitionHeight = human_input__crawlToCrouchTransitionHeight

  // Reset move when transferring to/from crawl in aim mode while we move
  // Why: To prevent the sight of the weapon from getting under the ground.
  let isCrawlHeight = phys.currentState.height <= crawlToAnyTransitionHeight
  let isBelowCrawlToCrouchHeight = phys.currentState.height <= crawlToCrouchTransitionHeight
  let transitionFromCrawlToCrouch = (crouch && isBelowCrawlToCrouchHeight)
  if (human_input__crawlingReject &&
     is_action_active(uint16(human_input__move)) &&
     (isCrawlHeight || transitionFromCrawlToCrouch || crawl))
    shouldUpdateWalkDir = false
    reset_digital_action_sticky_toggle(uint16(human_input__move))
    phys.producedCT |> human_control_state_set_walk_dir(float2(0, 0))

  let shouldUpdateLookDir = (is_action_active(uint16(human_input__aim)) ||
                            is_action_active(uint16(human_input__aimDelta)) ||
                            is_action_active(uint16(human_input__look)) ||
                            human_input__currentVertLookAngleLimit != human_input__prevVertLookAngleLimit)
  update_movement(info.dt, human_input__aim, human_input__aimDelta,
                  human_input__look, human_input__move,
                  human_input__sprint, human_input__perspWk,
                  human_input__forceLookMode,
                  human_input__blockLookModeCounter,
                  human_input__aimAngleOffset, vehicleInputAim, isInVehicle,
                  shouldUpdateLookDir, shouldUpdateWalkDir, human_input__lookDirClamp / 180.f,
                  deg_to_rad(human_input__currentVertLookAngleLimit), human_input__aimingSensMult,
                  human_input__resetSprintMovementThreshold,
                  human_input__resetSprintMoveThreshold,
                  human_input__lookAngleTau,
                  human_vehicle__isShootingPassenger,
                  human_net_phys, human_input__aimAngle,
                  human_input__lookAngle)

  let leanXState = get_analog_axis_action_state(uint16(human_input__leanX))
  if leanXState.bActive
    phys.producedCT |> human_control_state_set_lean_position(human_input__blockLeaningCounter > 0 ? 0.0 : leanXState.x)

  let inputShoot = human_vehicle__isShootingPassenger ? vehicleInputShoot ?? human_input__shoot : human_input__shoot
  let mainAttackIsMelee = get_bool(human_weap__currentGunEid, "gun__melee") ?? false
  if is_action_active(uint16(inputShoot)) && human_input__canShoot
    // We block shooting right after we drop a weapon, so we'll not shoot with our 'not dropped weapon' on the client, while we
    // still wait for server reply.
    let isShootBlocked = info.curTime - human_input__lastWeaponChangeInput < get_interp_delay_time(human_net_phys)
    let shoot = get_digital_action_state(uint16(inputShoot)).bState || is_button_pressed(uint16(inputShoot)) || phys.producedCT.haveUnenqueuedHctShoot
    let shootFlag = (shoot && !isShootBlocked)
    if shootFlag != phys.producedCT.lastEnqueuedHctShoot
      phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, shootFlag)
    if shootFlag && !mainAttackIsMelee
      human_input__lastShootInput = info.curTime
      // Reset sprinting when started shooting
      reset_digital_action_sticky_toggle(uint16(human_input__sprint))
      phys.producedCT.haveUnenqueuedHctShoot = true
  else
    phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, false)

  let isSprintAction = (get_digital_action_state(uint16(human_input__sprint)).bState || is_button_pressed(uint16(human_input__sprint)))
  let isSprintingMove = (get_analog_stick_action_state(uint16(human_input__move)).y > human_input__sprintMoveThreshold ||
                         get_stick_value(uint16(human_input__move)).y > human_input__sprintMoveThreshold)
  let isSprinting = (is_action_active(uint16(human_input__move)) &&
                     is_action_active(uint16(human_input__sprint)) &&
                     isSprintingMove && isSprintAction)
  var sprint = isSprinting && !aim2

  // Reset sprinting when aiming
  if aim && phys.producedCT |> is_control_bit_set(HumanPhysControlType HCT_SPRINT)
    reset_digital_action_sticky_toggle(uint16(human_input__sprint))

  // Reset aiming when transferring to sprint
  if sprint && phys.producedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM)
    reset_digital_action_sticky_toggle(uint16(human_input__aim1))
    reset_digital_action_sticky_toggle(uint16(human_input__aim2))

  if human_weap__throwMode
    aim = false

  // Reset sprinting when we want to crouch/crawl
  if (crawl || crouch) && phys.producedCT |> is_control_bit_set(HumanPhysControlType HCT_SPRINT)
    reset_digital_action_sticky_toggle(uint16(human_input__sprint))
    sprint = false

  if sprint
    if !aim
      human_input__standState = 0
      crawl = false
      crouch = false
    reset_digital_action_sticky_toggle(uint16(human_input__aim1))

  if sprint && !(crouch || crawl)
    aim = false
    reset_digital_action_sticky_toggle(uint16(human_input__holdBreath))

  phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, aim)
  phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, crawl)
  phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, crouch)

  human_net_phys |> set_ct_controlbit(HumanPhysControlType HCT_JUMP, uint16(human_input__jump))

  human_net_phys |> set_ct_controlbit(HumanPhysControlType HCT_RELOAD, uint16(human_input__reload))

  input_melee(info.curTime, is_gamepad_input(), human_input__melee, human_input__canShoot, mainAttackIsMelee, inputShoot, isSprinting,
              human_melee_charge__targetFound, human_melee_charge__longPressTime, human_input__wishMelee,
              phys, human_melee_charge__activateAtTime, human_input__meleeInputStartTime, human_melee_charge__lastMeleeButtonState,
              human_melee_charge__forceEnabled)

  if aim
    if is_control_bit_set(phys.producedCT, HumanPhysControlType HCT_JUMP)
      reset_digital_action_sticky_toggle(uint16(human_input__holdBreath))
    human_net_phys |> set_ct_controlbit(HumanPhysControlType HCT_SPRINT, uint16(human_input__holdBreath))
  else
    phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SPRINT, isSprinting)

  let inputZoom = human_vehicle__isShootingPassenger && vehicleInputZoom != null ? *vehicleInputZoom : human_input__zoom
  human_net_phys |> set_ct_controlbit(HumanPhysControlType HCT_ZOOM_VIEW, uint16(inputZoom))

  if !aim && does_action_block_sprint(eid)
    phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SPRINT, false)

  if phys.currentState |> human_phys_state_stoppedSprint()
    reset_digital_action_sticky_toggle(uint16(human_input__sprint))


[es(tag=input, on_appear, on_event=EventOnEntityReset)]
def human_input_entity_reset_es(evt : Event;
                                human_input__perspWk : float;
                                transform : float3x4&;
                                human_input__currentVertLookAngleLimit : float2;
                                var human_net_phys : HumanActor&;
                                var human_input__aimAngle : float2&)
  apply_human_input_tm(human_input__perspWk, transform[0],
                       deg_to_rad(human_input__currentVertLookAngleLimit),
                       human_net_phys, human_input__aimAngle)


[es(tag=input)]
def human_input_entity_teleported_es(evt : EventOnEntityTeleported;
                                     human_input__perspWk : float;
                                     human_input__currentVertLookAngleLimit : float2;
                                     var human_net_phys : HumanActor&;
                                     var human_input__aimAngle : float2&)
  let invPrevTm = inverse(evt.prevtm)
  let dir = angles_to_dir(human_input__aimAngle)
  let newDir = rotate(evt.newtm, rotate(invPrevTm, dir))
  human_input__aimAngle = dir_to_angles(newDir)

  update_look_dir(human_net_phys,
                  human_input__aimAngle,
                  float2(0, 0),
                  deg_to_rad(human_input__currentVertLookAngleLimit),
                  human_input__perspWk)
  update_walk_dir(human_net_phys)

[es]
def human_input_switch_camera_es(evt : EventDaInputActionTriggered;
                                 human_input__cameraNext : int;
                                 human_input__aim1 : int;
                                 human_input__aim2 : int;
                                 input__enabled : bool;
                                 camera_input__disabled : bool = false)
  if !input__enabled || camera_input__disabled
    return

  if evt.action == uint16(human_input__cameraNext)
    let playerEid = get_local_player_eid()
    if playerEid != INVALID_ENTITY_ID
      let isTps = get_cur_cam_entity() |> get_bool("isTpsView") ?? false
      let isAim1 = (is_action_active(uint16(human_input__aim1))
                    ? (get_digital_action_state(uint16(human_input__aim1)).bState || is_button_pressed(uint16(human_input__aim1)))
                    : false)
      let isAim2 = (is_action_active(uint16(human_input__aim2))
                    ? get_digital_action_state(uint16(human_input__aim2)).bState
                    : false)

      if !isAim1 && !isAim2 // Not aiming mode, just switch camera
        sendEvent(playerEid, [[CmdSwitchCamera]])
      elif isTps // Already TPS, just reset sticky toggled aiming mode
        reset_digital_action_sticky_toggle(uint16(human_input__aim1))
      else // If TPS is not active, switch camera and reset sticky toggled aiming
        reset_digital_action_sticky_toggle(uint16(human_input__aim1))
        sendEvent(playerEid, [[CmdSwitchCamera]])


[es(REQUIRE=isInVehicle, track=human_anim__vehicleSelected)]
def human_input_in_vehicle_es(evt : Event;
                              human_anim__vehicleSelected : ecs::EntityId;
                              camNames : Array&;
                              activeCamIdxBeforeEnterVehicle : int;
                              input__enabled : bool)
  if !input__enabled
    return

  if human_anim__vehicleSelected == INVALID_ENTITY_ID
    let playerEid = get_local_player_eid()
    query(playerEid) <| $ [es] (activeCamName : das_string const?)
      if activeCamName != null
        let cameraName = *activeCamName |> string()
        let hasCamera = (find_index(camNames, cameraName) >= 0)

        if !hasCamera
          sendEvent(playerEid, [[CmdSwitchCameraByIndex index=activeCamIdxBeforeEnterVehicle]])
  else
    sendEvent(human_anim__vehicleSelected, [[CmdTryToSwitchCameraInVehicle]])


[es(REQUIRE=camNames)]
def switch_camera_in_vehicle_es(evt : CmdTryToSwitchCameraInVehicle)
  let playerEid = get_local_player_eid()
  if playerEid != INVALID_ENTITY_ID
    query(playerEid) <| $ [es] (possessed : ecs::EntityId const?)
      if possessed != null
        query(*possessed) <| $ [es] (activeCamIdx : int const?;
                                     var activeCamIdxBeforeEnterVehicle : int&)
          activeCamIdxBeforeEnterVehicle = activeCamIdx ?? 0

    sendEvent(playerEid, [[CmdSwitchCameraByIndex index=0]])

[es(tag=input, track=possessedByPlr)]
def human_input_disable_aim_on_hero_change(evt : Event;
                                           possessedByPlr : EntityId;
                                           var human_net_phys : HumanActor)
  if !possessedByPlr
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, false)