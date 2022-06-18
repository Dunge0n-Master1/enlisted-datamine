require ecs
require game.es.events
require game.es.input.input_events
require enlisted.events_enlisted
require DagorInput
require EnlistedHuman
require HumanPhys
require DagorMathUtils


def init(var human_input__artilleryStrike : int&)
  human_input__artilleryStrike = int(get_action_handle("Human.ArtilleryStrike", TYPEGRP_DIGITAL))


def reset(var human_input__artilleryStrike : int&)
  human_input__artilleryStrike = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def artillery_input_appear(evt : Event; var human_input__artilleryStrike : int&)
  init(human_input__artilleryStrike)

[es(tag=input)]
def artillery_input(evt : EventDaInputInit; var human_input__artilleryStrike : int&)
  if evt.init
    init(human_input__artilleryStrike)
  else
    reset(human_input__artilleryStrike)

[es(tag=input)]
def artillery_input_action_triggered(evt : EventDaInputActionTriggered;
                                     eid : EntityId;
                                     human_input__artilleryStrike : int;
                                     input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__artilleryStrike
    sendEvent(eid, [[RequestOpenArtilleryMap]])

[es(tag=input, after=human_input_es)]
def artillery_radio_lock_input_es(evt : UpdateStageUpdateInput;
                                  human_weap__radioMode : bool;
                                  var human_net_phys : HumanActor&)
  if human_weap__radioMode
    human_net_phys.phys.producedCT |> human_control_state_set_neutral_ctrl()
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_CROUCH, true)

[es(track=human_weap__radioMode)]
def artillery_radio_orient(evt : Event;
                           var human_input__aimAngle : float2&;
                           var human_net_phys : HumanActor&;
                           var radioMode__prevAimAngle : float2&;
                           radioMode__vertThreshold : float;
                           human_weap__radioMode : bool)
  if human_weap__radioMode
    radioMode__prevAimAngle = human_input__aimAngle
    human_net_phys.phys.currentState.velocity = float3()
    human_input__aimAngle.y = radioMode__vertThreshold
  else
    human_input__aimAngle = radioMode__prevAimAngle

  let bodyNewDir = float2(human_input__aimAngle.x, 0.)
  let dir = angles_to_dir(bodyNewDir)

  human_net_phys.phys.currentState.bodyOrientDir = dir.xz

  human_net_phys.phys.producedCT |> human_control_state_set_wish_look_dir(dir)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(dir)