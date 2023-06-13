require ecs
require DngNet
require game.es.events
require common_shooter.events_common_shooter
require DagorInput
require DngHuman
require HumanPhys
require game.es.input.input_events
require common_shooter.es.mortar.mortar_common
require game.es.device_state_common
require DagorMath
require DagorMathUtils
require math.base
require Dacoll
require Gun
require DngWeapon
require DaWeaponProps
require DagorSystem
require DagorMath
require enlisted.events_enlisted

def init(var mortar_input__cancel : int&; var mortar_input__switchShellType : int&)
  mortar_input__cancel = int(get_action_handle("Mortar.Cancel", TYPEGRP_DIGITAL))
  mortar_input__switchShellType = int(get_action_handle("Mortar.SwitchShellType", TYPEGRP_DIGITAL))


def reset(var mortar_input__cancel : int&; var mortar_input__switchShellType : int&)
  mortar_input__cancel = int(BAD_ACTION_HANDLE)
  mortar_input__switchShellType = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def mortar_input_appear_es(evt : Event; var mortar_input__cancel : int&; var mortar_input__switchShellType : int&)
  init(mortar_input__cancel, mortar_input__switchShellType)

[es(tag=input)]
def mortar_input_es(evt : EventDaInputInit; var mortar_input__cancel : int&; var mortar_input__switchShellType : int&)
  if evt.init
    init(mortar_input__cancel, mortar_input__switchShellType)
  else
    reset(mortar_input__cancel, mortar_input__switchShellType)

[es(tag=input, REQUIRE=hero, on_appear, track=human_weap__mortarMode)]
def mortar_switch_action_set(evt : Event; human_weap__mortarMode : bool)
  activate_action_set(get_action_set_handle("Mortar"), human_weap__mortarMode)

[es(tag=input)]
def mortar_input_cancel(evt : EventDaInputActionTriggered;
                        eid : EntityId;
                        input__enabled : bool;
                        mortar_input__cancel : int)
  if input__enabled && int(evt.action) == mortar_input__cancel
    send_net_event(eid, [[EventMortarCanceled]])

[es(tag=input)]
def mortar_input_switch_shell_type(evt : EventDaInputActionTriggered;
                                   eid : EntityId;
                                   input__enabled : bool;
                                   mortar_input__switchShellType : int;
                                   human_weap__currentGunEid : EntityId)
  if input__enabled && int(evt.action) == mortar_input__switchShellType && has(human_weap__currentGunEid, "mortar")
    send_net_event(eid, [[RequestNextGunAmmoHolderType]])

[es(tag=input, after=human_input_es)]
def mortar_lock_input(info : UpdateStageUpdateInput;
                      human_weap__mortarMode : bool;
                      var human_net_phys : HumanActor&)
  if !human_weap__mortarMode
    return
  assume producedCT = human_net_phys.phys.producedCT
  let wasShoot = producedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT)
  producedCT |> human_control_state_set_neutral_ctrl()
  producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, true)
  producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, wasShoot)

def add_horizontal_offset(src : float3; dir : float2; dist : float)
  let offset = dir * dist
  return float3(src.x + offset.x, src.y, src.z + offset.y)

def get_pitch_at_distance(src : float3; dir : float2; dist : float)
  let h = 1000.
  let from = add_horizontal_offset(src, dir, dist) + float3(0., h, 0.)
  let down = float3(0., -1., 0.)
  var norm : float3
  var t = h * 2.
  var pmat : int
  if traceray_normalized_lmesh(from, down, t, pmat, norm)
    let endPoint = from + down * t
    let vdist = endPoint.y - src.y
    let hdist = sqrt(square(endPoint.x - src.x) + square(endPoint.z - src.z))
    return atan2(vdist, hdist)
  return 0.

[es(tag=gameClient, REQUIRE_NOT=human_input, REQUIRE=watchedByPlr, no_order)]
def mortar_spectator_distance_es(info : UpdateStageInfoAct;
                                 human_net_phys : HumanActor;
                                 human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es] (mortar__minTargetDistance : float;
                                              mortar__distanceLimit : float;
                                              var mortar__targetDistance : float&;
                                              mortar__spectatorDistanceMinMaxAngle = float2(0.8297, 1.4720))
    assume ct = human_net_phys.phys.appliedCT
    assume minMaxAngle = mortar__spectatorDistanceMinMaxAngle
    mortar__targetDistance = cvt(dir_to_angles(ct.wishShootDir).y, minMaxAngle.x, minMaxAngle.y, mortar__distanceLimit, mortar__minTargetDistance)

[es(tag=input, after=human_input_es)]
def mortar_input_controls_es(input : UpdateStageUpdateInput;
                             human_input__aim : int;
                             human_weap__mortarMode : bool;
                             human_weap__currentGunEid : EntityId;
                             var human_net_phys : HumanActor&;
                             var human_input__aimAngle : float2&)
  if !human_weap__mortarMode
    return

  query(human_weap__currentGunEid) <| $ [es] (gun : Gun;
                                              gun__curShellId : ShellPropIds;
                                              mortar__initDir : float2;
                                              mortar__horzLimits : float2;
                                              device_anim__state : int;
                                              mortar__lockedControl : bool;
                                              mortar__distanceLimit : float;
                                              mortar__cameraPitchChangeVisc : float = 0.8;
                                              mortar__minTargetDistance : float = 0.0;
                                              mortar__distanceSensMult : float = 100.0;
                                              mortar__checkHeightDistMult : float = 3.5;
                                              var mortar__targetDir : float2&;
                                              var mortar__targetPos : float3&;
                                              var mortar__targetDistance : float&;
                                              var mortar__cameraPitch : float&)
    let asAim = get_analog_stick_action_state(uint16(human_input__aim))
    if !asAim.bActive
      return

    assume ct = human_net_phys.phys.producedCT
    assume shootNodePos = gun.shootNodePos
    var curYaw = 0.
    if !mortar__lockedControl
      let initialYaw = (mortar__initDir.x != 0. || mortar__initDir.y != 0.) ? atan2(-mortar__initDir.y, mortar__initDir.x) : 0.
      let minYaw = initialYaw + deg_to_rad(mortar__horzLimits.x)
      let maxYaw = initialYaw + deg_to_rad(mortar__horzLimits.y)
      let wishYaw = renorm_ang(human_input__aimAngle.x, initialYaw)
      curYaw = norm_s_ang(clamp(wishYaw, minYaw, maxYaw))
      sincos(curYaw, mortar__targetDir.y, mortar__targetDir.x)
      mortar__targetDir.y = -mortar__targetDir.y
      mortar__targetDistance = clamp(mortar__targetDistance + asAim.y * mortar__distanceSensMult,
                                     mortar__minTargetDistance, mortar__distanceLimit)
      mortar__targetPos = add_horizontal_offset(shootNodePos, mortar__targetDir, mortar__targetDistance)
      if wishYaw < minYaw || wishYaw > maxYaw
        human_input__aimAngle.x = curYaw

      var wishPitch = get_pitch_at_distance(shootNodePos, mortar__targetDir, mortar__targetDistance)
      if wishPitch < 0.
        var checkHeightDistMult = mortar__checkHeightDistMult
        if mortar__checkHeightDistMult < 2.
          checkHeightDistMult = 2.
          logerr("mortar.checkHeightDistMult can't be < 2.0 (template: {getEntityTemplateName(human_weap__currentGunEid)})")
        var checkDistance = 1.
        while checkDistance < mortar__targetDistance
          let pitch = get_pitch_at_distance(shootNodePos, mortar__targetDir, checkDistance)
          wishPitch = max(wishPitch, pitch)
          if wishPitch > 0.
            wishPitch = 0.
            break
          checkDistance *= checkHeightDistMult
      human_input__aimAngle.y = approach(mortar__cameraPitch, wishPitch, input.dt, mortar__cameraPitchChangeVisc)
      mortar__cameraPitch = human_input__aimAngle.y
    else
      curYaw = (mortar__targetDir.x != 0. || mortar__targetDir.y != 0.) ? atan2(-mortar__targetDir.y, mortar__targetDir.x) : 0.
      human_input__aimAngle.x = curYaw

    let lookDir = angles_to_dir(human_input__aimAngle)
    if device_anim__state == int(DeviceAnimState DEVICE_STATE_USE) || device_anim__state == int(DeviceAnimState DEVICE_STATE_FIRE)
      let speed = get_shell_speed(gun__curShellId)
      var mortarGunDir = float3(1, 0, 0)
      calculate_arc_high_start_dir(shootNodePos, mortar__targetPos, speed, mortarGunDir)
      let shootDir = angles_to_dir(float2(curYaw, dir_to_angles(mortarGunDir).y))
      ct |> human_control_state_set_wish_shoot_dir(shootDir)
    ct |> human_control_state_set_wish_look_dir(lookDir)
