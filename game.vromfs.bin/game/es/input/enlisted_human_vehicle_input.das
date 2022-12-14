require ecs
require game.es.input.input_events
require DagorInput
require enlisted.events_enlisted
require EnlistedWalkerai
require EnlistedNet
require game.es.squad_order_common


def init(var human_input__exitVehicleAlone : int&)
  human_input__exitVehicleAlone = int(get_action_handle("Human.LeaveVehicleAlone", TYPEGRP_DIGITAL))

def reset(var human_input__exitVehicleAlone : int&)
  human_input__exitVehicleAlone = int(BAD_ACTION_HANDLE)


[es(tag=input, on_appear)]
def enlisted_vehicle_input_appear_es(evt : Event;
                                     var human_input__exitVehicleAlone : int&)
  init(human_input__exitVehicleAlone)


[es(tag=input)]
def enlisted_human_vehicle_input_es(evt : EventDaInputInit;
                                    var human_input__exitVehicleAlone : int&)
  if evt.init
    init(human_input__exitVehicleAlone)
  else
    reset(human_input__exitVehicleAlone)


[es(tag=input)]
def human_vehicle_exit_alone_es(evt : EventDaInputActionTriggered;
                                eid : EntityId;
                                transform : float3x4;
                                squad_member__squad : EntityId;
                                vehicle__lastEid aka player_vehicle__lastEid : EntityId;
                                isInVehicle : bool;
                                input__enabled : bool;
                                human_input__exitVehicleAlone : int;
                                human_input__use : int)
  if input__enabled && isInVehicle && int(evt.action) == human_input__exitVehicleAlone && !has(vehicle__lastEid, "airplane")
    // TODO2: we should not just trigger an action as this will fail in cases where humanUseAction and human_input__exitVehicleAlone
    // are the same. In this case humanUseAction triggers a vehicle exit, and then it is immidiately stopped when we send it again.
    // sadly, simple get_digital_action_state(humanUseAction).bState did not work as it broke completely on consoles.
    // A better way to simulate user key presses is needed
    send_action_event(action_handle_t(human_input__use))
    query(squad_member__squad) <| $ [es] (squad__allMembers : EidList)
      for squadMemberEid in squad__allMembers
        if squadMemberEid == eid
          continue

        query(squadMemberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (isInVehicle : bool;
                                                                 vehicle__lastEid : EntityId)
          if isInVehicle && vehicle__lastEid == player_vehicle__lastEid
            send_net_event(squadMemberEid, [[RequestPersonalSquadMateOrder
              orderType=int(SquadMateOrder ESMO_USE_VEHICLE),
              orderPosition=transform[3],
              orderUseEntity = vehicle__lastEid
            ]])