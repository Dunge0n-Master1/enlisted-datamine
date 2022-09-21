require ecs
require app
require game.es.events
require game.es.input.input_events
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
                               human_input__jump : int;
                               human_input__crawl : int;
                               human_input__melee : int;
                               input__enabled : bool)
  if !input__enabled
    return

  let action = int(evt.action)
  if action == human_input__jump || action == human_input__melee || action == human_input__crawl
    bipod__enabled = false

[es(tag=input, after=human_common_input_action_triggered_es)]
def human_bipod_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                          input__enabled : bool;
                                          human_input__bipodToggle : int;
                                          human_input__standState : int;
                                          human__aimTm : float3x4;
                                          bipod__placeable : bool;
                                          bipod__placePos : float3;
                                          bipod__placeNormal : float3;
                                          var bipod__enabled : bool&;
                                          var bipod__isCrawl : bool&;
                                          var bipod__anchorPos : float3&;
                                          var bipod__anchorDir : float3&;
                                          var bipod__anchorNormal : float3&)
  if !input__enabled || int(evt.action) != human_input__bipodToggle
    return

  if !bipod__placeable
    return

  if bipod__enabled
    bipod__enabled = false
  else
    bipod__enabled = true
    bipod__isCrawl = human_input__standState == int(HumanPhysControlType HCT_CRAWL)
    bipod__anchorPos = bipod__placePos
    bipod__anchorNormal = bipod__isCrawl ? bipod__placeNormal : float3(0., 1., 0.)
    bipod__anchorDir = calculate_anchor_dir(bipod__isCrawl, bipod__placeNormal, human__aimTm)


    var bipodHeight = bipod__isCrawl ? BIPOD_HEIGHT_CRAWL : BIPOD_HEIGHT
    if !bipod__isCrawl
      // Speacial check for small windows. Try to fit a bipod.
      let EPS = 1e-2
      let from = bipod__placePos + bipod__placeNormal * EPS
      let to = bipod__placePos + bipod__placeNormal * bipodHeight
      var queryOut = ShapeQueryOutput()
      if sphere_cast(from, to, 0.05, queryOut, -1)
        bipodHeight *= 0.25

    bipod__anchorPos += bipod__placeNormal * bipodHeight

[es(tag=input, REQUIRE=hero, before=start_async_phys_sim_es)] // before start_async_phys_sim_es due to usage of sphere_cast
def human_bipod_check_es(info : ParallelUpdateFrameDelayed;
                         human_weap__currentGunEid : EntityId;
                         human_input__aimAngle : float2;
                         human_input__standState : int;
                         human__aimTm : float3x4;
                         human_net_phys : HumanActor;
                         human_net_phys__isSwimming : bool;
                         human_net_phys__isOnGround : bool;
                         human_net_phys__isUnderwater : bool;
                         isDowned, isAlive : bool;
                         bipod__enabled : bool;
                         bipod__checkPlacingInterval : float;
                         bipod__pitchLimit : float2;
                         bipod__crawlLimit : float4;
                         human_attached_gun__attachedGunEid : EntityId;
                         var bipod__nextCheckPlacingAtTime : float&;
                         var bipod__placePos : float3&;
                         var bipod__placeNormal : float3&;
                         var bipod__placeable : bool&)
  if bipod__enabled
    return

  if bipod__nextCheckPlacingAtTime > 0.f && bipod__nextCheckPlacingAtTime >= info.curTime
    return

  bipod__nextCheckPlacingAtTime = info.curTime + bipod__checkPlacingInterval

  let isInAir = (uint(human_net_phys.phys.currentState.isInAirHistory) & 1u) != 0u
  let isHumanPhysStateValid = (!isDowned &&
                                isAlive &&
                               !isInAir &&
                               !human_attached_gun__attachedGunEid &&
                               !human_net_phys__isSwimming &&
                               !human_net_phys__isUnderwater &&
                                human_net_phys__isOnGround &&
                                human_net_phys.phys.currentState.moveState == HUMoveState EMS_STAND)
  if !isHumanPhysStateValid
    bipod__placeable = false
    return

  query(human_weap__currentGunEid) <| $ [es] (gun__bipodOffset : float3)
    assume humanTraceHandle = human_net_phys.phys.traceHandle

    let isCrawl = human_input__standState == int(HumanPhysControlType HCT_CRAWL)
    let res = calc_bipod_placing(human_weap__currentGunEid, isCrawl,
                                 bipod__crawlLimit, bipod__pitchLimit,
                                 human_input__aimAngle, human__aimTm,
                                 gun__bipodOffset,
                                 humanTraceHandle)
    bipod__placeable   = res.canBePlaced
    bipod__placePos    = res.placePos
    bipod__placeNormal = res.placeNormal

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
                              bipod__yawLimit : float2;
                              bipod__pitchLimit : float2;
                              bipod__crawlLimit : float4;
                              bipod__isCrawl : bool;
                              var human_net_phys : HumanActor&;
                              var human_input__aimAngle : float2&)
  if !bipod__enabled
    return

  let anchorAngles = dir_to_angles(bipod__anchorDir)
  let center = norm_ang(anchorAngles.x)
  let limit  = norm_ang(float2(center + bipod__yawLimit.x, center + bipod__yawLimit.y))
  human_input__aimAngle.x = norm_s_ang(clamp_ang(human_input__aimAngle.x, limit))

  if bipod__isCrawl
    human_input__aimAngle = clamp_angles_by_dir(human_input__aimAngle, bipod__crawlLimit, bipod__anchorDir)
  else
    human_input__aimAngle.y = clamp(human_input__aimAngle.y, deg_to_rad(bipod__pitchLimit.x), deg_to_rad(bipod__pitchLimit.y))

  let aimDir = angles_to_dir(human_input__aimAngle)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_look_dir(aimDir)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(aimDir)

[es(tag=input, on_event=EventComponentsDisappear, REQUIRE=(hero, human_weap__currentGunEid), track=human_weap__currentGunEid)]
def human_bipod_reset_es(evt : Event; var bipod__enabled : bool&)
  bipod__enabled = false

[es(tag=input, track=bipod__enabled)]
def human_bipod_reset_aim_es(evt : Event; bipod__enabled : bool; var human_net_phys : HumanActor)
  if !bipod__enabled
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, false)

[es(tag=input, track=(isDowned, isAlive))]
def human_bipod_reset_on_death_es(evt : Event; isDowned, isAlive : bool; var bipod__enabled : bool&)
  if isDowned || !isAlive
    bipod__enabled = false

[es(tag=netClient, REQUIRE=hero, track=bipod__enabled, after=bipod_solve_limits_es)]
def human_request_placing_es(evt : Event;
                             eid : EntityId;
                             bipod__enabled : bool;
                             bipod__isCrawl : bool;
                             bipod__placePos : float3;
                             bipod__yawLimit : float2;
                             bipod__anchorPos : float3;
                             bipod__anchorDir : float3;
                             bipod__anchorNormal : float3)
  send_net_event(eid, [[RequestBipodPlacing enabled      = bipod__enabled,
                                            isCrawl      = bipod__isCrawl,
                                            placePos     = bipod__placePos,
                                            yawLimit     = bipod__yawLimit,
                                            anchorPos    = bipod__anchorPos,
                                            anchorDir    = bipod__anchorDir,
                                            anchorNormal = bipod__anchorNormal]])
