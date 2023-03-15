require ecs
require EnlistedNet
require app
require math
require math.base
require game.utils.hero
require EnlistedWalkerai
require game.es.events
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require DagorMathUtils
require DaWeaponProps
require DaWeapons
require Gun
require EnlistedWeapon
require EnlistedHuman
require HumanPhys
require EnlistedPhys
require GamePhys
require PhysVars
require game.es.device_state_common
require common_shooter.es.mortar.mortar_common
require enlisted.events_enlisted

def start_mortar_mode(ownerEid : ecs::EntityId const)
  query(ownerEid) <| $ [es] (var human_weap__mortarMode : bool&; isInVehicle : bool)
    if isInVehicle
      return
    human_weap__mortarMode = true

[es(REQUIRE=mortar)]
def mortar_triggered(evt : CmdWeapPhysUpdate;
                     gun__ammo : int;
                     var mortar__shootPressed : bool&)
  if !evt.isForReal || gun__ammo <= 0
    mortar__shootPressed = false
    return

  if evt.gctrl.shoot
    mortar__shootPressed = true
  elif mortar__shootPressed
    mortar__shootPressed = false
    start_mortar_mode(evt.owner)

def start_fire_animation(var device_animation__fireAt : float&; device_animation__startAt : float)
  if device_animation__fireAt < device_animation__startAt
    device_animation__fireAt = get_sync_time()

[es]
def mortar_strike(evt : CmdStartMortarStrikeAtPos; human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=mortar)] (var mortar__targetPos : float3&; var mortar__targetAcquiredFlag : bool&)
    mortar__targetPos = evt.pos
    mortar__targetAcquiredFlag = true

[es(tag=server, on_event=EventMortarCanceled)]
def mortar_mode_canceled(evt : Event; var human_weap__mortarMode : bool&)
  human_weap__mortarMode = false

[es(tag=server)]
def mortar_target_selected(evt : EventMortarTargetSelected; eid : EntityId)
  send_net_event(eid, [[CmdStartMortarStrikeAtPos pos=evt.targetPos]])

[es(tag=server, track=(human_weap__currentGunSlot, human_weap__gunEids), REQUIRE=(human_weap__currentGunSlot, human_weap__gunEids))]
def exit_mortar_mod_on_weapon_switch(evt : Event;
                                     var human_weap__mortarMode : bool&)
  if human_weap__mortarMode
    human_weap__mortarMode = false

[es(track=human_weap__mortarMode)]
def mortar_animation_start_end_control(evt : Event;
                                       human_weap__gunEids : ecs::EidList;
                                       human_weap__curGunSlot : int;
                                       human_weap__mortarMode : bool)
  let weapEid = human_weap__gunEids[human_weap__curGunSlot]
  query(weapEid) <| $ [es(REQUIRE=mortar)] (var device_animation__isActive : bool&;
                                            var device_animation__startAt : float&;
                                            var device_animation__endAt : float&)
    if human_weap__mortarMode
      device_animation__isActive = true
      device_animation__startAt = get_sync_time()
    else
      device_animation__endAt = get_sync_time()

[es(tag=gameClient, track=human_weap__mortarMode, REQUIRE=hero)]
def mortar_mode_change_on_client(evt : Event;
                                 human_weap__mortarMode : bool;
                                 var radioMode__prevPose : int&;
                                 var human_input__standState : int&)
  if human_weap__mortarMode
    radioMode__prevPose = human_input__standState
    human_input__standState = int(HumanPhysControlType HCT_CROUCH)
  elif radioMode__prevPose >= 0
    human_input__standState = radioMode__prevPose


def reload(owner_eid : ecs::EntityId;
           gun_eid : ecs::EntityId;
           at_time : float;
           dt : float)
  sendEvent(owner_eid, [[CmdRequestReload atTime=at_time - dt, gunEid= gun_eid]])

[es]
def mortar_phys(evt : CmdWeapPhysUpdate;
                eid : ecs::EntityId;
                gun__curShellId : ShellPropIds;
                mortar__targetPos : float3;
                device_animation__startAt : float;
                device_anim__state : int;
                gun__ammo : int;
                var mortar__targetAcquiredFlag : bool&;
                var mortar__fireFlag : bool&;
                var device_animation__fireAt : float&)
  if !evt.isForReal
    return
  if gun__ammo == 0
    reload(evt.owner, eid, evt.atTime, evt.dt)

  var gctrl = evt.gctrl
  let isShootPressed = gctrl.shoot

  gctrl.shoot = mortar__fireFlag
  let isInMortarMode = get_bool(evt.owner, "human_weap__mortarMode") ?? false
  let isDeviceReady = device_anim__state == int(DeviceAnimState DEVICE_STATE_USE) || device_anim__state == int(DeviceAnimState DEVICE_STATE_FIRE)
  let updateGun = gun__ammo > 0 && isInMortarMode && isDeviceReady && int(gun__curShellId.shellId) >= 0
  let shouldStartAnimation = mortar__targetAcquiredFlag
  mortar__fireFlag = false
  mortar__targetAcquiredFlag = false

  if isShootPressed && isInMortarMode
    send_net_event(evt.owner, [[EventMortarTargetSelected targetPos=mortar__targetPos]])

  if updateGun
    if shouldStartAnimation
      start_fire_animation(device_animation__fireAt, device_animation__startAt)
  else
    gctrl.shoot = false

  sendEventImmediate(eid, [[CmdGunUpdate atTime=evt.atTime, isForReal=evt.isForReal, seed=phys_time_to_seed(evt.atTime), gctrl=gctrl, gloc=evt.gloc]])

[es]
def mortar_on_device_shoot(evt : EventOnDeviceShoot; var mortar__fireFlag : bool&)
  mortar__fireFlag = true

[es(tag=server, track=gun__curShellId)]
def mortar_init_distance_limit(evt : Event;
                               gun__curShellId : ShellPropIds;
                               var mortar__distanceLimit : float&;
                               mortar__distanceLimitMargin : float = 1.0)
  let speed = get_shell_speed(gun__curShellId)
  let g = gravity()
  if g != 0.0
    mortar__distanceLimit = (speed * speed / g) - mortar__distanceLimitMargin

[es(track=(isDowned, isAlive))]
def mortar_exit_on_downed(evt : Event; isDowned : bool; isAlive : bool; var human_weap__mortarMode : bool&)
  if isDowned || !isAlive
    human_weap__mortarMode = false

[es(tag=server, track=possessedByPlr)]
def mortar_exit_if_non_player(evt : Event; possessedByPlr : EntityId; var human_weap__mortarMode : bool&)
  if !possessedByPlr
    human_weap__mortarMode = false

[es(on_appear, REQUIRE=mortar, before=anim_phys_init_es)]
def mortar_register_pitch_var(evt : Event; mortar__pitchPhysVarName : string; var phys_vars : PhysVars; var mortar__pitchPhysVarId : int&)
  mortar__pitchPhysVarId = registerVar(phys_vars, mortar__pitchPhysVarName, 0.0)

[es(tag=gameClient, no_order)]
def mortar_update_pitch(info : ParallelUpdateFrameDelayed;
                        eid : EntityId;
                        gun__owner : EntityId;
                        mortar__pitchPhysVarId : int;
                        var phys_vars : PhysVars)
  query(gun__owner) <| $ [es] (human_weap__mortarMode : bool;
                               human_weap__currentGunEid : EntityId;
                               human_net_phys : HumanActor)
    if !human_weap__mortarMode || human_weap__currentGunEid != eid || mortar__pitchPhysVarId < 0
      return

    let prevPitch = dir_to_angles(human_net_phys.phys.previousState.gunDir).y
    let curPitch = dir_to_angles(human_net_phys.phys.currentState.gunDir).y
    let interpk = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
    let pitchDeg = rad_to_deg(lerp(prevPitch, curPitch, interpk))
    setVar(phys_vars, mortar__pitchPhysVarId, pitchDeg)

[es(on_appear, before=anim_phys_init_es)]
def mortar_mode_register_pivot_offset_var(evt : Event;
                                          var phys_vars : PhysVars;
                                          mortar_mode__pivotOffsetPhysVarName : string;
                                          var mortar_mode__pivotOffsetPhysVarId : int&)
  mortar_mode__pivotOffsetPhysVarId = registerVar(phys_vars, mortar_mode__pivotOffsetPhysVarName, 0.0)

[es(tag=gameClient, before=human_anim_es)]
def mortar_mode_update_pivot_offset(info : ParallelUpdateFrameDelayed;
                                    human_weap__mortarMode : bool;
                                    mortar_mode__pivotOffsetPhysVarId : int;
                                    mortar_mode__pivotOffsetInMortarMode : float;
                                    var phys_vars : PhysVars)
  setVar(phys_vars, mortar_mode__pivotOffsetPhysVarId, human_weap__mortarMode ? mortar_mode__pivotOffsetInMortarMode : 0.0)
