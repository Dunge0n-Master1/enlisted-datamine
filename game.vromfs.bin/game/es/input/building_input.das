require ecs
require EnlistedNet
require game.es.events
require game.es.input.input_events
require enlisted.events_enlisted
require DagorInput


def reset(var human_input__nextBuildingType : int&;
          var human_input__buildingAction : int&)
  human_input__nextBuildingType = int(BAD_ACTION_HANDLE)
  human_input__buildingAction = int(BAD_ACTION_HANDLE)


def init(var human_input__nextBuildingType : int&;
         var human_input__buildingAction : int&)
  human_input__nextBuildingType = int(get_action_handle("Human.NextBuildingType", TYPEGRP_DIGITAL))
  human_input__buildingAction = int(get_action_handle("Human.BuildingAction", TYPEGRP_DIGITAL))

[es(tag=input, on_appear)]
def building_input_appear_es(evt : Event;
                             var human_input__nextBuildingType : int&;
                             var human_input__buildingAction : int&)
  init(human_input__nextBuildingType, human_input__buildingAction)

[es(tag=input)]
def building_input_es(evt : EventDaInputInit;
                      var human_input__nextBuildingType : int&;
                      var human_input__buildingAction : int&)
  if evt.init
    init(human_input__nextBuildingType, human_input__buildingAction)
  else
    reset(human_input__nextBuildingType, human_input__buildingAction)

[es(tag=input)]
def build_next_type_input_es(evt : EventDaInputActionTriggered;
                             human_weap__currentGunEid : EntityId;
                             human_input__nextBuildingType : int;
                             input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__nextBuildingType
    send_net_event(human_weap__currentGunEid, [[CmdNextBuildingType]])

[es(tag=input)]
def start_build_action_input_es(evt : EventDaInputActionTriggered;
                                eid : EntityId;
                                human_use_object__selectedBuilding : EntityId;
                                human_input__buildingAction : int;
                                input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__buildingAction
    send_net_event(eid, [[EventDismantleBuilding target=human_use_object__selectedBuilding]])

[es(tag=input)]
def cancel_build_action_input_es(evt : EventDaInputActionTerminated;
                                 eid : EntityId;
                                 human_input__buildingAction : int;
                                 input__enabled : bool)
  if input__enabled && int(evt.action) == human_input__buildingAction
    send_net_event(eid, [[EventDismantleBuilding target=INVALID_ENTITY_ID]])