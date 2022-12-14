require ecs
require net
require DagorInput
require game.es.events
require game.es.input.input_events
require common_shooter.events_common_shooter
require enlisted.events_enlisted


def init(var human_inventory_input__useFlask : int&)
  human_inventory_input__useFlask = int(get_action_handle("Inventory.UseFlask", TYPEGRP_DIGITAL))


def reset(var human_inventory_input__useFlask : int&)
  human_inventory_input__useFlask = int(BAD_ACTION_HANDLE)


[es(tag=input, on_appear)]
def human_inventory_input_flask_appear(evt : Event;
                                       var human_inventory_input__useFlask : int&)
  init(human_inventory_input__useFlask)


[es(tag=input)]
def human_inventory_input_flask_init(evt : EventDaInputInit;
                                     var human_inventory_input__useFlask : int&)
  if evt.init
    init(human_inventory_input__useFlask)
  else
    reset(human_inventory_input__useFlask)


[es(tag=input, after=human_input_es)]
def human_inventory_input_flask_use_action_triggered(evt : EventDaInputActionTriggered;
                                                     eid : EntityId;
                                                     input__enabled : bool;
                                                     human_inventory_input__useFlask : int)
  if input__enabled && human_inventory_input__useFlask == int(evt.action)
    send_net_event(eid, [[CmdFlaskUse]])


[es]
def human_inventory_input_flask_use_action_terminated(evt : EventDaInputActionTerminated;
                                                      eid : EntityId;
                                                      human_inventory_input__useFlask : int;
                                                      input__enabled : bool)
  if input__enabled && human_inventory_input__useFlask == int(evt.action)
    send_net_event(eid, [[CmdFlaskUseCancel]])


[es(before=interrupt_item_use_es)]
def human_inventory_input_flask_reset_sticky_toggle_on_interrupt(evt : EventInterruptItemUse;
                                                                 human_inventory__entityToUse : EntityId;
                                                                 human_inventory_input__useFlask : int)
  if has(human_inventory__entityToUse, "flask")
    reset_digital_action_sticky_toggle(uint16(human_inventory_input__useFlask))
