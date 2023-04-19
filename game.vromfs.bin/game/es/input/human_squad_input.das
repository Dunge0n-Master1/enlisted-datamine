require ecs
require app
require game.es.input.input_events
require DagorInput
require player
require DngCamera
require DngHuman
require DngNet
require enlisted.events_enlisted

def init(var human_input__squadNext : int&)
  human_input__squadNext = int(get_action_handle("Human.SquadNext", TYPEGRP_DIGITAL))


def reset(var human_input__squadNext : int&)
  human_input__squadNext = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def human_squad_input_appear_es(evt : Event;
                                var human_input__squadNext : int&)
  init(human_input__squadNext)

[es(tag=input)]
def human_squad_input_es(evt : EventDaInputInit;
                         var human_input__squadNext : int&)
  if evt.init
    init(human_input__squadNext)
  else
    reset(human_input__squadNext)

[es(tag=input)]
def human_squad_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                          eid : EntityId;
                                          input__enabled : bool;
                                          human_input__squadNext : int)
  if input__enabled && int(evt.action) == human_input__squadNext
    ecs::query(eid) <| $ [es] (squad_member__squad : EntityId)
      send_net_event(squad_member__squad, [[RequestSquadChangeLeader eid=INVALID_ENTITY_ID]])