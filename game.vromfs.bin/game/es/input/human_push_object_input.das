require ecs
require EnlistedNet
require ecs.common
require DagorInput
require game.es.input.input_events
require enlisted.events_enlisted


def init(var human_input__pushObject : int&)
  human_input__pushObject = int(get_action_handle("Human.PushObject", TYPEGRP_DIGITAL))


def reset(var human_input__pushObject : int&)
  human_input__pushObject = int(BAD_ACTION_HANDLE)


[es(tag=input)]
def human_push_object_input_setup(evt : EventDaInputInit; var human_input__pushObject : int&)
  if evt.init
    init(human_input__pushObject)
  else
    reset(human_input__pushObject)


[es(tag=input, on_appear)]
def human_push_object_input_appear(evt : Event; var human_input__pushObject : int&)
  init(human_input__pushObject)


[es(tag=input, on_disappear)]
def human_push_object_input_disappear(evt : Event; var human_input__pushObject : int&)
  reset(human_input__pushObject)


[es(tag=input)]
def push_object_input_es(evt : EventDaInputActionTriggered;
                         eid : EntityId;
                         human_use_object__selectedObject : EntityId;
                         human_input__pushObject : int)
  if !!human_use_object__selectedObject && int(evt.action) == human_input__pushObject
    send_net_event(eid, [[CmdPushObject target=human_use_object__selectedObject]])


[es(tag=input)]
def terminate_push_object_input_es(evt : EventDaInputActionTerminated;
                                   eid : EntityId;
                                   human_input__pushObject : int)
  if int(evt.action) == human_input__pushObject
    send_net_event(eid, [[CmdPushObject target=INVALID_ENTITY_ID]])
