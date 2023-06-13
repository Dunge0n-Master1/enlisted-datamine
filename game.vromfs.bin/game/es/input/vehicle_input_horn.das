require ecs
require DagorInput
require game.es.input.input_events
require vehicle_sounds_net.modules.vehicle_sounds_net_events
require player
require DngNet

def init(var vehicle_input_horn : int&; vehicle_input_action : string)
  vehicle_input_horn = int(get_action_handle(vehicle_input_action, TYPEGRP_DIGITAL))
  if vehicle_input_horn != int(BAD_ACTION_HANDLE)
    activate_action_set(uint16(vehicle_input_horn), true)

def reset(var vehicle_input_horn : int&)
  if vehicle_input_horn != int(BAD_ACTION_HANDLE)
    activate_action_set(uint16(vehicle_input_horn), false)
  vehicle_input_horn = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def vehicle_input_horn_appear(evt : Event; var vehicle_input_horn : int&; vehicle_input_action : string)
  init(vehicle_input_horn, vehicle_input_action)

[es(tag=input, on_disappear)]
def vehicle_input_horn_disappear(evt : Event; var vehicle_input_horn : int&)
  reset(vehicle_input_horn)

[es(tag=input)]
def vehicle_input_horn_init_reset(evt : EventDaInputInit; var vehicle_input_horn : int&; vehicle_input_action : string)
  if evt.init
    init(vehicle_input_horn, vehicle_input_action)
  else
    reset(vehicle_input_horn)


[es(tag=input)]
def vehicle_input_horn_triggered(evt : EventDaInputActionTriggered;
                                 eid : EntityId;
                                 input__enabled : bool;
                                 vehicle_input_horn : int)
  if input__enabled && int(evt.action) == vehicle_input_horn
    query() <| $ [es(REQUIRE=hero)] (human_vehicle__isHoldingGunPassenger : bool)
      if !human_vehicle__isHoldingGunPassenger
        send_net_event(eid, [[CmdVehicleHornRequest enable=true, player=get_local_player_eid()]])


[es(tag=input)]
def vehicle_input_horn_terminated(evt : EventDaInputActionTerminated;
                                  eid : EntityId;
                                  input__enabled : bool;
                                  vehicle_input_horn : int)
  if input__enabled && int(evt.action) == vehicle_input_horn
    send_net_event(eid, [[CmdVehicleHornRequest enable=false, player=get_local_player_eid()]])
