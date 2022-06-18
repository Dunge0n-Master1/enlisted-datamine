require ecs
require EnlistedNet
require game.es.events
require common_shooter.events_common_shooter
require DagorInput
require EnlistedHuman
require HumanPhys
require game.es.input.input_events


def init(var mortar_input__cancel : int&)
  mortar_input__cancel = int(get_action_handle("Mortar.Cancel", TYPEGRP_DIGITAL))


def reset(var mortar_input__cancel : int&)
  mortar_input__cancel = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def mortar_input_appear_es(evt : Event; var mortar_input__cancel : int&)
  init(mortar_input__cancel)

[es(tag=input)]
def mortar_input_es(evt : EventDaInputInit; var mortar_input__cancel : int&)
  if evt.init
    init(mortar_input__cancel)
  else
    reset(mortar_input__cancel)

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
