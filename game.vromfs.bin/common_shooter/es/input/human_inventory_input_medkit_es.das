require ecs
require DagorInput
require game.es.events
require game.es.input.input_events
require common_shooter.events_common_shooter

def init(var human_inventory_input__useMedkit : int&)
  human_inventory_input__useMedkit = int(get_action_handle("Inventory.UseMedkit", TYPEGRP_DIGITAL))


def reset(var human_inventory_input__useMedkit : int&)
  human_inventory_input__useMedkit = int(BAD_ACTION_HANDLE)


[es(tag=input, on_appear)]
def human_inventory_input_medkit_appear_es(evt : Event;
                                           var human_inventory_input__useMedkit : int&)
  init(human_inventory_input__useMedkit)


[es(tag=input)]
def human_inventory_input_medkit_init_es(evt : EventDaInputInit;
                                         var human_inventory_input__useMedkit : int&)
  if evt.init
    init(human_inventory_input__useMedkit)
  else
    reset(human_inventory_input__useMedkit)


[es]
def human_inventory_input_medkit_terminated_es(evt : EventDaInputActionTerminated;
                                               eid : EntityId;
                                               human_inventory_input__useMedkit : int;
                                               heal__continuousInput : bool;
                                               input__enabled : bool)
  if !input__enabled
    return

  if human_inventory_input__useMedkit == int(evt.action) && heal__continuousInput
    sendEvent(eid, [[CmdMedkitUseCancel]])


[es(before=interrupt_item_use_es)]
def human_inventory_input_medkit_reset_sticky_toggle_on_interrupt(evt : EventInterruptItemUse;
                                                                  human_inventory_input__useMedkit : int)
  reset_digital_action_sticky_toggle(uint16(human_inventory_input__useMedkit))
