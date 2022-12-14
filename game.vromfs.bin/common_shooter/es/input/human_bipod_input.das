require ecs
require app
require game.es.events
require game.es.input.input_events
require game.events_game
require enlisted.events_enlisted
require DagorInput
require DagorMath
require DagorMathUtils
require math.base
require math.ang
require player
require EnlistedHuman
require AnimV20
require GeomNodeTree
require Dacoll
require HumanPhys
require GamePhys
require EnlistedNet
require common_shooter.events_common_shooter
require common_shooter.es.human.bipod_common


def init(var human_input__bipodToggle : int&)
  human_input__bipodToggle = int(get_action_handle("Human.BipodToggle", TYPEGRP_DIGITAL))

def reset(var human_input__bipodToggle : int&)
  human_input__bipodToggle = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def human_bipod_input_appear_es(evt : Event; var human_input__bipodToggle : int&)
  init(human_input__bipodToggle)

[es(tag=input)]
def human_bipod_input_es(evt : EventDaInputInit; var human_input__bipodToggle : int&)
  if evt.init
    init(human_input__bipodToggle)
  else
    reset(human_input__bipodToggle)


[es(tag=input, before=human_common_input_action_triggered_es)]
def human_bipod_input_reset_es(evt : EventDaInputActionTriggered;
                               var bipod__enabled : bool&;
                               var bipod__placeable : bool&;
                               human_input__jump : int;
                               human_input__crawl : int;
                               human_input__melee : int;
                               input__enabled : bool)
  if !input__enabled
    return

  let action = int(evt.action)
  if action == human_input__jump || action == human_input__melee || action == human_input__crawl
    bipod__enabled = false
    bipod__placeable = false

[es(tag=input, after=human_common_input_action_triggered_es)]
def human_bipod_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                          eid : EntityId;
                                          input__enabled : bool;
                                          human_input__bipodToggle : int;
                                          human_net_phys : HumanActor;
                                          human__aimTm : float3x4;
                                          human_input__aimAngle : float2;
                                          var human_input__standState : int&;
                                          var bipod__placeable : bool&;
                                          var bipod__placeCrawl : bool&;
                                          var bipod__placePos : float3&;
                                          var bipod__placeHeight : float&;
                                          var bipod__placeOffset : float3&;
                                          var bipod__placeNormal : float3&;
                                          var bipod__placeYawLimit : float&;
                                          var bipod__placeRecoilMult : float&;
                                          var bipod__enabled : bool&;
                                          var bipod__validateTimer : float&;
                                          var bipod__isCrawl : bool&;
                                          var bipod__anchorPos : float3&;
                                          var bipod__anchorDir : float3&;
                                          var bipod__anchorHeight : float&;
                                          var bipod__anchorOffset : float3&;
                                          var bipod__anchorNormal : float3&;
                                          var bipod__anchorYawLimit : float2&;
                                          var bipod__recoilMult : float&;
                                          var bipod__pitchLimit : float2&;
                                          var bipod__prevCcdPos : float3&;
                                          var bipod__prevAngle : float2&;
                                          var bipod__lastValidPos : float3&;
                                          var bipod__lastValidDir : float3&;
                                          var bipod__isValidPos : bool&)
  if !input__enabled || int(evt.action) != human_input__bipodToggle
    return

  if bipod__enabled
    bipod__enabled = false
    return

  let saved_placeable       = bipod__placeable
  let saved_placeCrawl      = bipod__placeCrawl
  let saved_placePos        = bipod__placePos
  let saved_placeHeight     = bipod__placeHeight
  let saved_placeOffset     = bipod__placeOffset
  let saved_placeNormal     = bipod__placeNormal
  let saved_placeYawLimit   = bipod__placeYawLimit
  let saved_placeRecoilMult = bipod__placeRecoilMult

  solve_bipod_placing(eid, true)

  if saved_placeable && !bipod__placeable
    bipod__placeable       = saved_placeable
    bipod__placeCrawl      = saved_placeCrawl
    bipod__placePos        = saved_placePos
    bipod__placeHeight     = saved_placeHeight
    bipod__placeOffset     = saved_placeOffset
    bipod__placeNormal     = saved_placeNormal
    bipod__placeYawLimit   = saved_placeYawLimit
    bipod__placeRecoilMult = saved_placeRecoilMult

  if !bipod__placeable
    return

  let isCrawl = human_input__standState == int(HumanPhysControlType HCT_CRAWL)
  if isCrawl != bipod__placeCrawl
    return

  bipod__enabled        = true
  bipod__isCrawl        = bipod__placeCrawl
  bipod__recoilMult     = bipod__placeRecoilMult
  bipod__anchorPos      = bipod__placePos
  bipod__anchorDir      = calc_anchor_dir(bipod__isCrawl, bipod__placeNormal, human__aimTm)
  bipod__anchorHeight   = bipod__placeHeight
  bipod__anchorOffset   = bipod__placeOffset
  bipod__anchorNormal   = bipod__isCrawl ? bipod__placeNormal : float3(0.0, 1.0, 0.0)
  bipod__anchorYawLimit = float2(-bipod__placeYawLimit, bipod__placeYawLimit)

  bipod__pitchLimit     = float2(BIPOD_DEFAULT_PITCH_MIN, BIPOD_DEFAULT_PITCH_MAX)
  bipod__validateTimer  = BIPOD_WAIT_BEFORE_VALIDATE

  if human_input__standState == int(HumanPhysControlType HCT_CROUCH)
    human_input__standState = 0

  bipod__prevCcdPos = get_human_ccd_pos(human_net_phys)
  bipod__prevAngle  = human_input__aimAngle

  bipod__lastValidPos = float3(human_net_phys.phys.currentState.location.P)
  bipod__lastValidDir = human_net_phys.phys.appliedCT.wishShootDir
  bipod__isValidPos = true

[es(tag=input, REQUIRE=hero, before=start_async_phys_sim_es)] // before start_async_phys_sim_es due to usage of sphere_cast
def human_bipod_check_es(info : ParallelUpdateFrameDelayed;
                         eid : EntityId;
                         bipod__enabled : bool;
                         bipod__checkPlacingInterval : float;
                         var bipod__nextCheckPlacingAtTime : float&)
  if bipod__enabled
    return

  if bipod__nextCheckPlacingAtTime > 0.0 && bipod__nextCheckPlacingAtTime >= info.curTime
    return
  bipod__nextCheckPlacingAtTime = info.curTime + bipod__checkPlacingInterval

  solve_bipod_placing(eid, false)


[es(tag=input, REQUIRE=hero, after=after_input_sync)]
def bipod_input_es(evt : UpdateStageUpdateInput;
                   bipod__enabled : bool;
                   bipod__isCrawl : bool;
                   var human_input__standState : int&;
                   var human_net_phys : HumanActor&)
  if !bipod__enabled
    return

  human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, true)
  human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_JUMP, false)
  human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_MELEE, false)
  if bipod__isCrawl
    human_input__standState = int(HumanPhysControlType HCT_CRAWL)
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_CRAWL, true)

[es(tag=input, REQUIRE=hero, after=after_input_sync)]
def bipod_clamp_aim_angles_es(evt : UpdateStageUpdateInput;
                              bipod__enabled : bool;
                              bipod__anchorDir : float3;
                              bipod__anchorYawLimit : float2;
                              bipod__pitchLimit : float2;
                              bipod__crawlLimit : float2;
                              bipod__isCrawl : bool;
                              bipod__lastValidDir : float3;
                              bipod__isValidPos : bool;
                              bipod__validateTimer : float;
                              var human_net_phys : HumanActor&;
                              var human_input__aimAngle : float2&;
                              var bipod__prevAngle : float2&)
  if !bipod__enabled
    return

  let aimCoef = BIPOD_ANGLE_AIMING_COEF
  let yawDeltaMax   = BIPOD_MAX_YAW_PER_SECOND * evt.dt
  let pitchDeltaMax = BIPOD_MAX_PITCH_PER_SECOND * evt.dt
  let yawDelta   = clamp(norm_s_ang(human_input__aimAngle.x - bipod__prevAngle.x) * aimCoef, -yawDeltaMax, yawDeltaMax)
  let pitchDelta = clamp(norm_s_ang(human_input__aimAngle.y - bipod__prevAngle.y) * aimCoef, -pitchDeltaMax, pitchDeltaMax)
  human_input__aimAngle.x = norm_ang(bipod__prevAngle.x + yawDelta)
  human_input__aimAngle.y = norm_s_ang(bipod__prevAngle.y + pitchDelta)
  bipod__prevAngle = human_input__aimAngle

  let anchorAngles = dir_to_angles(bipod__anchorDir)
  let center = norm_ang(anchorAngles.x)

  let limit  = norm_ang(float2(center + bipod__anchorYawLimit.x, center + bipod__anchorYawLimit.y))
  human_input__aimAngle.x = norm_s_ang(clamp_ang(human_input__aimAngle.x, limit))

  if bipod__isCrawl
    human_input__aimAngle.y = clamp(human_input__aimAngle.y, deg_to_rad(bipod__crawlLimit.x), deg_to_rad(bipod__crawlLimit.y))
  else
    human_input__aimAngle.y = clamp(human_input__aimAngle.y, deg_to_rad(bipod__pitchLimit.x), deg_to_rad(bipod__pitchLimit.y))

  if bipod__validateTimer > 0.0
    human_input__aimAngle.y = approach(human_input__aimAngle.y, 0.0, evt.dt, human_input__aimAngle.y < 0.0 ? 0.1 : 0.9)

  if !bipod__isValidPos
    let validAngles = dir_to_angles(bipod__lastValidDir)
    let targetYaw = human_input__aimAngle.x + norm_s_ang(validAngles.x - human_input__aimAngle.x)

    let dyawTarget = norm_s_ang(targetYaw - center)
    let dyawCurrent = norm_s_ang(human_input__aimAngle.x - center)

    if (dyawTarget < 0.0 && dyawCurrent < dyawTarget) || (dyawTarget > 0.0 && dyawCurrent > dyawTarget)
      human_input__aimAngle.x = approach(human_input__aimAngle.x, targetYaw, evt.dt, 0.05)

    if (validAngles.y < 0.0 && human_input__aimAngle.y < validAngles.y) || (validAngles.y > 0.0 && human_input__aimAngle.y > validAngles.y)
      human_input__aimAngle.y = approach(human_input__aimAngle.y, validAngles.y, evt.dt, 0.05)

  let aimDir = angles_to_dir(human_input__aimAngle)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_look_dir(aimDir)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(aimDir)


[es(tag=input, on_event=EventComponentsDisappear, REQUIRE=(hero, human_weap__currentGunEid), track=human_weap__currentGunEid)]
def human_bipod_reset_es(evt : Event; var bipod__enabled : bool&; var bipod__placeable : bool&)
  bipod__enabled = false
  bipod__placeable = false

[es(tag=input, track=bipod__enabled)]
def human_bipod_reset_aim_es(evt : Event; bipod__enabled : bool; var human_net_phys : HumanActor)
  if !bipod__enabled
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, false)

[es(tag=input, track=(isDowned, isAlive))]
def human_bipod_reset_on_death_es(evt : Event; isDowned, isAlive : bool; var bipod__enabled : bool&; var bipod__placeable : bool&)
  if isDowned || !isAlive
    bipod__enabled = false
    bipod__placeable = false

[es(tag=netClient, REQUIRE=hero, track=bipod__enabled)]
def human_request_placing_es(evt : Event;
                             eid : EntityId;
                             bipod__enabled : bool;
                             bipod__isCrawl : bool;
                             bipod__anchorPos : float3;
                             bipod__anchorDir : float3;
                             bipod__anchorHeight : float;
                             bipod__anchorOffset : float3;
                             bipod__anchorNormal : float3;
                             bipod__anchorYawLimit : float2;
                             bipod__recoilMult : float)
  send_net_event(eid, [[RequestBipodPlacing enabled        = bipod__enabled,
                                            isCrawl        = bipod__isCrawl,
                                            anchorPos      = bipod__anchorPos,
                                            anchorDir      = bipod__anchorDir,
                                            anchorHeight   = bipod__anchorHeight,
                                            anchorOffset   = bipod__anchorOffset,
                                            anchorNormal   = bipod__anchorNormal,
                                            anchorYawLimit = bipod__anchorYawLimit,
                                            recoilMult     = bipod__recoilMult]])

[es(tag=input)]
def gun_bipod_mandatory_show_hint(evt : EventDaInputActionTriggered;
                                  input__enabled : bool;
                                  human_weap__canOperate : bool;
                                  human_input__shoot : int;
                                  human_input__reload : int;
                                  human_input__aim1 : int;
                                  human_input__aim2 : int)
  if !input__enabled || human_weap__canOperate
    return

  let action = int(evt.action)
  if action == human_input__shoot || action == human_input__reload || action == human_input__aim1 || action == human_input__aim2
    broadcastEvent([[CmdShowHint event="gun_needs_bipod", text="gun_needs_bipod", unique="gun_needs_bipod", ttl=2.0]])
