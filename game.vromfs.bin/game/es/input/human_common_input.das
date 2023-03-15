require ecs
require app
require game.es.events
require game.es.input.input_events
require game.es.input.input_common
require DagorInput
require HumanPhys
require EnlistedHuman
require game.es.action_common


def init(var human_input__jump : int&;
         var human_input__crawl : int&;
         var human_input__crouch : int&;
         var human_input__holdCrouch : int&;
         var human_input__melee : int&;
         var human_input__reload : int&;
         var human_input__recover : int&)
  human_input__jump = int(get_action_handle("Human.Jump", TYPEGRP_DIGITAL))
  human_input__crawl = int(get_action_handle("Human.Crawl", TYPEGRP_DIGITAL))
  human_input__crouch = int(get_action_handle("Human.Crouch", TYPEGRP_DIGITAL))
  human_input__holdCrouch = int(get_action_handle("Human.HoldCrouch", TYPEGRP_DIGITAL))
  human_input__melee = int(get_action_handle("Human.Melee", TYPEGRP_DIGITAL))
  human_input__reload = int(get_action_handle("Human.Reload", TYPEGRP_DIGITAL))
  human_input__recover = int(get_action_handle("Human.Recover", TYPEGRP_DIGITAL))


def reset(var human_input__jump : int&;
          var human_input__crawl : int&;
          var human_input__crouch : int&;
          var human_input__holdCrouch : int&;
          var human_input__melee : int&;
          var human_input__reload : int&;
          var human_input__recover : int&)
  human_input__jump = int(BAD_ACTION_HANDLE)
  human_input__crawl = int(BAD_ACTION_HANDLE)
  human_input__crouch = int(BAD_ACTION_HANDLE)
  human_input__holdCrouch = int(BAD_ACTION_HANDLE)
  human_input__melee = int(BAD_ACTION_HANDLE)
  human_input__reload = int(BAD_ACTION_HANDLE)
  human_input__recover = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def human_common_appear_es(evt : Event;
                           var human_input__jump : int&;
                           var human_input__crawl : int&;
                           var human_input__crouch : int&;
                           var human_input__holdCrouch : int&;
                           var human_input__melee : int&;
                           var human_input__reload : int&;
                           var human_input__recover : int&)
  init(human_input__jump, human_input__crawl, human_input__crouch, human_input__holdCrouch,
       human_input__melee, human_input__reload, human_input__recover)

[es(tag=input)]
def human_common_input_es(evt : EventDaInputInit;
                          var human_input__jump : int&;
                          var human_input__crawl : int&;
                          var human_input__crouch : int&;
                          var human_input__holdCrouch : int&;
                          var human_input__melee : int&;
                          var human_input__reload : int&;
                          var human_input__recover : int&;
                          var human_input__standState : int&)
  if evt.init
    init(human_input__jump, human_input__crawl, human_input__crouch, human_input__holdCrouch,
         human_input__melee, human_input__reload, human_input__recover)
  else
    reset(human_input__jump, human_input__crawl, human_input__crouch, human_input__holdCrouch,
          human_input__melee, human_input__reload, human_input__recover)
    human_input__standState = 0

[es(tag=input)]
def human_common_input_entity_reset_es(evt : EventOnEntityReset;
                                       human_input__jump : int;
                                       human_input__crawl : int;
                                       human_input__crouch : int;
                                       human_input__holdCrouch : int;
                                       human_input__melee : int;
                                       var human_net_phys : HumanActor&)
  assume ct = human_net_phys.phys.producedCT
  set_controlbit_touch(HumanPhysControlType HCT_JUMP, uint16(human_input__jump), ct)
  set_controlbit(HumanPhysControlType HCT_CRAWL, uint16(human_input__crawl), ct)
  set_controlbit(HumanPhysControlType HCT_CROUCH, uint16(human_input__crouch), ct)
  set_controlbit(HumanPhysControlType HCT_CROUCH, uint16(human_input__holdCrouch), ct)
  set_controlbit(HumanPhysControlType HCT_MELEE, uint16(human_input__melee), ct)

[es(tag=input)]
def human_common_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                           eid : EntityId;
                                           human_input__jump : int;
                                           human_input__crawl : int;
                                           human_input__crouch : int;
                                           human_input__holdCrouch : int;
                                           human_input__melee : int;
                                           var human_input__meleeInputStartTime : float&;
                                           human_input__reload : int;
                                           human_input__recover : int;
                                           input__enabled : bool;
                                           var human_net_phys : HumanActor&;
                                           var human_input__standState : int&;
                                           human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                                           human_input__shoot : int = -1;
                                           game_effect__dashEndTime : float = 0.f;
                                           game_effect__dashStartTime : float = 0.f;
                                           jetpack__enabled : bool = false;
                                           isInVehicle : bool = false;
                                           bipod__enabled : bool = false;
                                           burning__isBurning : bool = false)
  assume ct = human_net_phys.phys.producedCT
  let atTime = get_sync_time()
  let action = int(evt.action)
  if !input__enabled
    return
  if action == human_input__jump
    let dashJump = game_effect__dashEndTime > atTime && game_effect__dashStartTime <= atTime
    if human_net_phys.phys.canJump || jetpack__enabled || dashJump
      ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_JUMP, true)
      human_input__standState = 0
  elif action == human_input__melee || (action == human_input__shoot && get_bool(human_weap__currentGunEid, "gun__melee") ?? false)
    if !bipod__enabled && !is_control_bit_set(ct, HumanPhysControlType HCT_THROW_BACK) && !isInVehicle
      human_input__meleeInputStartTime = atTime
  elif action == human_input__crawl
    if !isInVehicle && !bipod__enabled
      human_input__standState = human_input__standState == int(HumanPhysControlType HCT_CRAWL) ? 0 : int(HumanPhysControlType HCT_CRAWL)
  elif action == human_input__crouch
    if !isInVehicle && !bipod__enabled
      human_input__standState = human_input__standState == int(HumanPhysControlType HCT_CROUCH) ? 0 : int(HumanPhysControlType HCT_CROUCH)
  elif action == human_input__holdCrouch
    if !isInVehicle && !bipod__enabled
      human_input__standState = int(HumanPhysControlType HCT_CROUCH)
  elif action == human_input__reload
    ct |> human_control_state_set_control_bit(HumanPhysControlType HCT_RELOAD, true)
  elif action == human_input__recover
    if !burning__isBurning && check_action_precondition(eid, "recover")
      run_action(eid, "recover")

[es(tag=input, after=human_weap_post_phys_es)]
def reset_melee_action_es(evt : CmdPostPhysUpdate;
                          var human_input__wishMelee : bool&)
  human_input__wishMelee = false

[es(tag=input)]
def human_common_input_action_terminated_es(evt : EventDaInputActionTerminated;
                                            human_input__holdCrouch : int;
                                            input__enabled : bool;
                                            human_input__melee : int;
                                            human_input__reload : int;
                                            var human_input__wishMelee : bool&;
                                            var human_input__standState : int&;
                                            var human_input__meleeInputStartTime : float&;
                                            human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                                            human_input__shoot : int = -1;
                                            isInVehicle : bool = false;
                                            bipod__enabled : bool = false;
                                            var human_input__isNeedHctReloadReset : bool&)
  let action = int(evt.action)
  if !input__enabled
    return
  if action == human_input__holdCrouch
    if !isInVehicle && !bipod__enabled
      human_input__standState = 0
  elif action == human_input__melee || (action == human_input__shoot && get_bool(human_weap__currentGunEid, "gun__melee") ?? false)
    human_input__wishMelee = human_input__meleeInputStartTime > 0.0
    human_input__meleeInputStartTime = -1.0
  elif action == human_input__reload
    human_input__isNeedHctReloadReset = true
