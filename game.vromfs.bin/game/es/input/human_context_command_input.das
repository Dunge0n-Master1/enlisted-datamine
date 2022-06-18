require ecs
require DagorInput
require game.es.input.input_events
require enlisted.events_enlisted


def init(var human_context_command__aContextCommand : int&;
         var human_context_command__aCancelContextCommand : int&;
         var human_context_command__switchCommandModeInput : int&)
  human_context_command__aContextCommand = int(get_action_handle("Human.ContextCommand", TYPEGRP_DIGITAL))
  human_context_command__aCancelContextCommand = int(get_action_handle("Human.CancelContextCommand", TYPEGRP_DIGITAL))
  human_context_command__switchCommandModeInput = int(get_action_handle("Human.SwitchContextCommandMode", TYPEGRP_DIGITAL))

def reset(var human_context_command__aContextCommand : int&;
          var human_context_command__aCancelContextCommand : int&;
          var human_context_command__switchCommandModeInput : int&)
  human_context_command__aContextCommand = int(BAD_ACTION_HANDLE)
  human_context_command__aCancelContextCommand = int(BAD_ACTION_HANDLE)
  human_context_command__switchCommandModeInput = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def human_context_command_input_on_create(evt : Event;
                                          var human_context_command__aContextCommand : int&;
                                          var human_context_command__aCancelContextCommand : int&;
                                          var human_context_command__switchCommandModeInput : int&)
  init(human_context_command__aContextCommand, human_context_command__aCancelContextCommand, human_context_command__switchCommandModeInput)

[es(tag=input, on_event=(EventEntityDestroyed, EventComponentsDisappear))]
def human_context_command_input_on_destroy(evt : Event;
                                           var human_context_command__aContextCommand : int&;
                                           var human_context_command__aCancelContextCommand : int&;
                                           var human_context_command__switchCommandModeInput : int&)
  reset(human_context_command__aContextCommand, human_context_command__aCancelContextCommand, human_context_command__switchCommandModeInput)

[es(tag=input)]
def human_context_command_input_on_init(evt : EventDaInputInit;
                                        var human_context_command__aContextCommand : int&;
                                        var human_context_command__aCancelContextCommand : int&;
                                        var human_context_command__switchCommandModeInput : int&)
  if evt.init
    init(human_context_command__aContextCommand, human_context_command__aCancelContextCommand, human_context_command__switchCommandModeInput)
  else
    reset(human_context_command__aContextCommand, human_context_command__aCancelContextCommand, human_context_command__switchCommandModeInput)

[es(tag=input)]
def human_context_command_input_on_action(evt : EventDaInputActionTriggered;
                                          eid : EntityId;
                                          input__enabled : bool;
                                          squad_member__squad : EntityId;
                                          squad_member__isPersonalContextCommandMode : bool;
                                          human_context_command__aContextCommand : int;
                                          human_context_command__aCancelContextCommand : int;
                                          human_context_command__switchCommandModeInput : int)
  if !input__enabled
    return

  if int(evt.action) == human_context_command__aContextCommand
    if squad_member__isPersonalContextCommandMode
      sendEvent(eid, [[ RqPersonalContextCommand ]])
    else
      sendEvent(eid, [[ RqContextCommand ]])
  elif int(evt.action) == human_context_command__aCancelContextCommand
    if squad_member__isPersonalContextCommandMode
      sendEvent(eid, [[ RqCancelPersonalContextCommand ]])
    else
      sendEvent(eid, [[ RqCancelContextCommand include_personal_orders=true ]])
  elif int(evt.action) == human_context_command__switchCommandModeInput
    query(squad_member__squad) <| $ [es] (squad__allMembers : EidList)
      for memberEid in squad__allMembers
        query(memberEid) <| $ [es] (var squad_member__isPersonalContextCommandMode : bool&)
          squad_member__isPersonalContextCommandMode = !squad_member__isPersonalContextCommandMode