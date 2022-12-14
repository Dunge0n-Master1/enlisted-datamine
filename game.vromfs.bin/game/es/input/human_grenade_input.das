require ecs
require app
require game.es.events
require game.es.input.input_events
require DagorInput
require HumanPhys
require EnlistedHuman


def init(var human_input__throw : int&;
         var human_input__throw2 : int&;
         var human_input__throw3 : int&;
         var human_input__throw4 : int&;
         var human_input__throw5 : int&;
         var human_input__throw6 : int&;
         var human_input__throwBack : int&;
         var human_input__throwDowned : int&)
  human_input__throw = int(get_action_handle("Human.Throw", TYPEGRP_DIGITAL))
  human_input__throw2 = int(get_action_handle("Human.Throw2", TYPEGRP_DIGITAL))
  human_input__throw3 = int(get_action_handle("Human.Throw3", TYPEGRP_DIGITAL))
  human_input__throw4 = int(get_action_handle("Human.Throw4", TYPEGRP_DIGITAL))
  human_input__throw5 = int(get_action_handle("Human.Throw5", TYPEGRP_DIGITAL))
  human_input__throw6 = int(get_action_handle("Human.Throw6", TYPEGRP_DIGITAL))
  human_input__throwBack = int(get_action_handle("Human.ThrowBack", TYPEGRP_DIGITAL))
  human_input__throwDowned = int(get_action_handle("Human.ThrowDowned", TYPEGRP_DIGITAL))


def reset(var human_input__throw : int&;
          var human_input__throw2 : int&;
          var human_input__throw3 : int&;
          var human_input__throw4 : int&;
          var human_input__throw5 : int&;
          var human_input__throw6 : int&;
          var human_input__throwBack : int&;
          var human_input__throwDowned : int&)
  human_input__throw = int(BAD_ACTION_HANDLE)
  human_input__throw2 = int(BAD_ACTION_HANDLE)
  human_input__throw3 = int(BAD_ACTION_HANDLE)
  human_input__throw4 = int(BAD_ACTION_HANDLE)
  human_input__throw5 = int(BAD_ACTION_HANDLE)
  human_input__throw6 = int(BAD_ACTION_HANDLE)
  human_input__throwBack = int(BAD_ACTION_HANDLE)
  human_input__throwDowned = int(BAD_ACTION_HANDLE)


def set_throwbit(var ct &; throw0; throw2; throw3; throw4; throw5; throw6)
  ct |> human_control_state_set_throw_state(false, HumanControlThrowSlot HCTS_EMPTY)
  if is_action_active(throw0) && get_digital_action_state(throw0).bState
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT0)
  if is_action_active(throw2) && get_digital_action_state(throw2).bState
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT1)
  if is_action_active(throw3) && get_digital_action_state(throw3).bState
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT2)
  if is_action_active(throw4) && get_digital_action_state(throw4).bState
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT3)
  if is_action_active(throw5) && get_digital_action_state(throw5).bState
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT4)
  if is_action_active(throw6) && get_digital_action_state(throw6).bState
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT5)

[es(tag=input, on_appear)]
def human_grenade_input_appear_es(evt : Event;
                                  var human_input__throw : int&;
                                  var human_input__throw2 : int&;
                                  var human_input__throw3 : int&;
                                  var human_input__throw4 : int&;
                                  var human_input__throw5 : int&;
                                  var human_input__throw6 : int&;
                                  var human_input__throwBack : int&;
                                  var human_input__throwDowned : int&)
  init(human_input__throw,
       human_input__throw2,
       human_input__throw3,
       human_input__throw4,
       human_input__throw5,
       human_input__throw6,
       human_input__throwBack,
       human_input__throwDowned)

[es(tag=input)]
def human_grenade_input_init_es(evt : EventDaInputInit;
                                var human_input__throw : int&;
                                var human_input__throw2 : int&;
                                var human_input__throw3 : int&;
                                var human_input__throw4 : int&;
                                var human_input__throw5 : int&;
                                var human_input__throw6 : int&;
                                var human_input__throwBack : int&;
                                var human_input__throwDowned : int&)
  if evt.init
    init(human_input__throw,
         human_input__throw2,
         human_input__throw3,
         human_input__throw4,
         human_input__throw5,
         human_input__throw6,
         human_input__throwBack,
         human_input__throwDowned)
  else
    reset(human_input__throw,
          human_input__throw2,
          human_input__throw3,
          human_input__throw4,
          human_input__throw5,
          human_input__throw6,
          human_input__throwBack,
          human_input__throwDowned)

[es(tag=input)]
def human_grenade_input_entity_reset_es(evt : EventOnEntityReset;
                                        human_input__throw : int;
                                        human_input__throw2 : int;
                                        human_input__throw3 : int;
                                        human_input__throw4 : int;
                                        human_input__throw5 : int;
                                        human_input__throw6 : int;
                                        var human_net_phys : HumanActor&)
  assume ct = human_net_phys.phys.producedCT
  ct |> set_throwbit(uint16(human_input__throw),
                     uint16(human_input__throw2),
                     uint16(human_input__throw3),
                     uint16(human_input__throw4),
                     uint16(human_input__throw5),
                     uint16(human_input__throw6))

[es(tag=input)]
def human_grenade_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                            input__enabled : bool;
                                            human_input__throw : int;
                                            human_input__throw2 : int;
                                            human_input__throw3 : int;
                                            human_input__throw4 : int;
                                            human_input__throw5 : int;
                                            human_input__throw6 : int;
                                            var human_net_phys : HumanActor&)
  if !input__enabled
    return

  assume ct = human_net_phys.phys.producedCT
  let action = int(evt.action)
  if action == human_input__throw
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT0)
  elif action == human_input__throw2
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT1)
  elif action == human_input__throw3
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT2)
  elif action == human_input__throw4
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT3)
  elif action == human_input__throw5
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT4)
  elif action == human_input__throw6
    ct |> human_control_state_set_throw_state(true, HumanControlThrowSlot HCTS_SLOT5)

[es(tag=input)]
def human_grenade_input_es(info : UpdateStageUpdateInput;
                           human_input__throw : int;
                           human_input__throw2 : int;
                           human_input__throw3 : int;
                           human_input__throw4 : int;
                           human_input__throw5 : int;
                           human_input__throw6 : int;
                           var human_net_phys : HumanActor&)
  assume ct = human_net_phys.phys.producedCT
  ct |> set_throwbit(uint16(human_input__throw),
                     uint16(human_input__throw2),
                     uint16(human_input__throw3),
                     uint16(human_input__throw4),
                     uint16(human_input__throw5),
                     uint16(human_input__throw6))

[es(tag=input, before=human_common_input_action_triggered_es)]
def human_throw_back_grenade_es(evt : EventDaInputActionTriggered;
                                input__enabled : bool;
                                human_input__throwBack : int;
                                human_use_object__selectedObject : EntityId;
                                var human_net_phys : HumanActor&)
  if !input__enabled || int(evt.action) != human_input__throwBack
    return
  ecs::query(human_use_object__selectedObject) <| $ [es(REQUIRE=shell__shell_id__shell_id)] ()
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_THROW_BACK, true)

[es(tag=input)]
def human_cancel_throw_back_grenade_es(evt : EventDaInputActionTerminated;
                                       input__enabled : bool;
                                       human_input__throwBack : int;
                                       var human_net_phys : HumanActor&)
  if !input__enabled || int(evt.action) != human_input__throwBack
    return
  human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_THROW_BACK, false)

[es(tag=input, before=human_common_input_action_triggered_es)]
def downed_human_throw_grenade_es(evt : EventDaInputActionTriggered;
                                  isDowned : bool;
                                  input__enabled : bool;
                                  human_input__throwDowned : int;
                                  var human_net_phys : HumanActor&)
  if input__enabled && isDowned && int(evt.action) == human_input__throwDowned
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_THROW_BACK, true)

[es(tag=input)]
def downed_human_cancel_throw_grenade_es(evt : EventDaInputActionTerminated;
                                         isDowned : bool;
                                         input__enabled : bool;
                                         human_input__throwDowned : int;
                                         var human_net_phys : HumanActor&)
  if input__enabled && isDowned && int(evt.action) == human_input__throwDowned
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_THROW_BACK, false)
