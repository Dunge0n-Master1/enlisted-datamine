require ecs
require EnlistedNet
require game.es.input.input_events
require DagorInput
require enlisted.events_enlisted

def initActions(var human_input__interactBombSite : int&)
  human_input__interactBombSite = int(get_action_handle("Human.Use", TYPEGRP_DIGITAL))

def resetActions(var human_input__interactBombSite : int&)
  human_input__interactBombSite = int(BAD_ACTION_HANDLE)


[es(tag=input)]
def human_interact_bomb_site_input_setup(evt : EventDaInputInit; var human_input__interactBombSite : int&)
  if evt.init
    initActions(human_input__interactBombSite)
  else
    resetActions(human_input__interactBombSite)

[es(tag=input, on_appear)]
def human_interact_bomb_site_input_appear(evt : Event; var human_input__interactBombSite : int&)
  initActions(human_input__interactBombSite)

[es(tag=input, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def human_interact_bomb_site_input_disappear(evt : Event; var human_input__interactBombSite : int&)
  resetActions(human_input__interactBombSite)

[es(tag=input)]
def human_interact_bomb_site_start_input_es(evt : EventDaInputActionTriggered;
                                            human_input__interactBombSite : int;
                                            input__enabled : bool;
                                            human_use_object__selectedObject : EntityId;
                                            var human_use_object__currentInteractBombSite : EntityId&)
  if input__enabled && int(evt.action) == human_input__interactBombSite
    human_use_object__currentInteractBombSite = human_use_object__selectedObject

[es(tag=input)]
def human_interact_bomb_site_stop_input_es(evt : EventDaInputActionTerminated;
                                           eid : EntityId;
                                           human_input__interactBombSite : int;
                                           human_use_object__currentInteractBombSite : EntityId;
                                           input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__interactBombSite
    send_net_event(human_use_object__currentInteractBombSite, [[CmdStopInteractBomb operatorEid=eid]])