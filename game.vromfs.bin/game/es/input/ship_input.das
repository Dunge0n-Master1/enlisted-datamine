require ecs
require Ship
require DngShip
require game.es.events
require game.es.input.input_events
require DagorInput


def init(var ship_input__throttle : int&;
         var ship_input__accel : int&;
         var ship_input__brake : int&;
         var ship_input__steer : int&)
  ship_input__throttle = int(get_action_handle("Ship.Throttle", TYPEGRP_AXIS))
  ship_input__accel = int(get_action_handle("Ship.Accel", TYPEGRP_AXIS))
  ship_input__brake = int(get_action_handle("Ship.Brake", TYPEGRP_AXIS))
  ship_input__steer = int(get_action_handle("Ship.Steer", TYPEGRP_AXIS))

  activate_action_set(get_action_set_handle("Ship"), true)


def reset(var ship_input__throttle : int&;
          var ship_input__accel : int&;
          var ship_input__brake : int&;
          var ship_input__steer : int&)
  ship_input__throttle = int(BAD_ACTION_HANDLE)
  ship_input__accel = int(BAD_ACTION_HANDLE)
  ship_input__brake = int(BAD_ACTION_HANDLE)
  ship_input__steer = int(BAD_ACTION_HANDLE)

  activate_action_set(get_action_set_handle("Ship"), false)


[es(tag=input, on_appear)]
def ship_input_on_appear(evt : Event;
                         var ship_input__throttle : int&;
                         var ship_input__accel : int&;
                         var ship_input__brake : int&;
                         var ship_input__steer : int&)
  init(ship_input__throttle, ship_input__accel, ship_input__brake, ship_input__steer);


[es(tag=input, on_disappear)]
def ship_input_on_disappear(evt : Event;
                            var ship_input__throttle : int&;
                            var ship_input__accel : int&;
                            var ship_input__brake : int&;
                            var ship_input__steer : int&)
  reset(ship_input__throttle, ship_input__accel, ship_input__brake, ship_input__steer);


[es(tag=input)]
def ship_input_on_dainput_init(evt : EventDaInputInit;
                               var ship_input__throttle : int&;
                               var ship_input__accel : int&;
                               var ship_input__brake : int&;
                               var ship_input__steer : int&)
  if evt.init
    init(ship_input__throttle, ship_input__accel, ship_input__brake, ship_input__steer)
  else
    reset(ship_input__throttle, ship_input__accel, ship_input__brake, ship_input__steer)


[es(tag=input)]
def ship_input_on_update_input(info : UpdateStageUpdateInput;
                               input__enabled : bool;
                               ship_input__throttle : int;
                               ship_input__accel : int;
                               ship_input__brake : int;
                               ship_input__steer : int;
                               var ship_net_phys : ShipActor)
  if !input__enabled
    return

  let throttle = get_analog_axis_action_state(uint16(ship_input__throttle))
  let accel = get_analog_axis_action_state(uint16(ship_input__accel))
  let brake = get_analog_axis_action_state(uint16(ship_input__brake))
  let steering = get_analog_axis_action_state(uint16(ship_input__steer))

  if throttle.bActive || accel.bActive || brake.bActive
    let throttleAxis = throttle.bActive ? throttle.x : 0.0
    let accelAxis = accel.bActive ? accel.x : 0.0
    let brakeAxis = brake.bActive ? brake.x : 0.0
    let throttle_val = clamp(throttleAxis + accelAxis - brakeAxis, -1.0, 1.0)
    ship_control_state_setAxisValue(ship_net_phys.phys.producedCT, EShipControlAxis SCA_PORT_ENGINE, throttle_val)
    ship_control_state_setAxisValue(ship_net_phys.phys.producedCT, EShipControlAxis SCA_STAR_ENGINE, throttle_val)

  if steering.bActive
    ship_control_state_setAxisValue(ship_net_phys.phys.producedCT, EShipControlAxis SCA_STEERING, steering.x)
