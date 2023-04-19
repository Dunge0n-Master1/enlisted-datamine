require ecs
require DngNet
require enlisted.events_enlisted
require game.es.input.input_events
require DagorInput

def init(var human_input__Hooray : int&)
  human_input__Hooray = int(get_action_handle("Human.Hooray", TYPEGRP_DIGITAL))

def reset(var human_input__Hooray : int&)
  human_input__Hooray = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def hooray_input_appear_es(evt : Event; var human_input__Hooray : int&)
  init(human_input__Hooray)

[es(tag=input)]
def hooray_input_es(evt : EventDaInputInit; input__enabled : bool; var human_input__Hooray : int&)
  if !input__enabled
    return
  if evt.init
    init(human_input__Hooray)
  else
    reset(human_input__Hooray)

[es(tag=input)]
def human_input_action_hooray_triggered_es(evt : EventDaInputActionTriggered;
                                           eid : EntityId;
                                           input__enabled : bool;
                                           human_input__Hooray : int)
  if input__enabled && int(evt.action) == human_input__Hooray
    send_net_event(eid, [[CmdHumanHoorayRequest]])