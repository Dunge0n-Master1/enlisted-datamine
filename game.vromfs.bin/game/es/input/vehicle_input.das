require ecs
require math.base
require vehicle
require game.es.events
require game.es.input.input_events
require DagorInput
require TouchInput


def init(var vehicle_input__steer : int&;
         var vehicle_input__throttle : int&;
         var vehicle_input__accel : int&;
         var vehicle_input__brake : int&;
         var vehicle_input__handBrake : int&)
  vehicle_input__steer     = int(get_action_handle("Vehicle.Steer", TYPEGRP_AXIS))
  vehicle_input__throttle  = int(get_action_handle("Vehicle.Throttle", TYPEGRP_AXIS))
  vehicle_input__accel     = int(get_action_handle("Vehicle.Accel", TYPEGRP_AXIS))
  vehicle_input__brake     = int(get_action_handle("Vehicle.Brake", TYPEGRP_AXIS))
  vehicle_input__handBrake = int(get_action_handle("Vehicle.HandBrake", TYPEGRP_DIGITAL))

  let vehicleHandle = get_action_set_handle("Vehicle")
  if int(vehicleHandle) != int(BAD_ACTION_SET_HANDLE)
    activate_action_set(vehicleHandle, true)


def reset(var vehicle_input__steer : int&;
          var vehicle_input__throttle : int&;
          var vehicle_input__accel : int&;
          var vehicle_input__brake : int&;
          var vehicle_input__handBrake : int&)
  vehicle_input__steer     = int(BAD_ACTION_HANDLE)
  vehicle_input__throttle  = int(BAD_ACTION_HANDLE)
  vehicle_input__accel     = int(BAD_ACTION_HANDLE)
  vehicle_input__brake     = int(BAD_ACTION_HANDLE)
  vehicle_input__handBrake = int(BAD_ACTION_HANDLE)

  let vehicleHandle = get_action_set_handle("Vehicle")
  if int(vehicleHandle) != int(BAD_ACTION_SET_HANDLE)
    activate_action_set(vehicleHandle, false)


[es(tag=input, on_appear)]
def vehicle_input_appear(evt : Event;
                         var vehicle_input__steer : int&;
                         var vehicle_input__throttle : int&;
                         var vehicle_input__accel : int&;
                         var vehicle_input__brake : int&;
                         var vehicle_input__handBrake : int&)
  init(vehicle_input__steer, vehicle_input__throttle, vehicle_input__accel, vehicle_input__brake, vehicle_input__handBrake)

[es(tag=input, on_disappear)]
def vehicle_input_disappear(evt : Event;
                            var vehicle_input__steer : int&;
                            var vehicle_input__throttle : int&;
                            var vehicle_input__accel : int&;
                            var vehicle_input__brake : int&;
                            var vehicle_input__handBrake : int&)
  reset(vehicle_input__steer, vehicle_input__throttle, vehicle_input__accel, vehicle_input__brake, vehicle_input__handBrake)

[es(tag=input)]
def vehicle_input_init_reset(evt : EventDaInputInit;
                             var vehicle_input__steer : int&;
                             var vehicle_input__throttle : int&;
                             var vehicle_input__accel : int&;
                             var vehicle_input__brake : int&;
                             var vehicle_input__handBrake : int&)
  if evt.init
    init(vehicle_input__steer, vehicle_input__throttle, vehicle_input__accel, vehicle_input__brake, vehicle_input__handBrake)
  else
    reset(vehicle_input__steer, vehicle_input__throttle, vehicle_input__accel, vehicle_input__brake, vehicle_input__handBrake)


[es(tag=input, on_appear, before=vehicle_input_driver_es)]
def init_vehicle_input_axes(evt : Event; var vehicle_input_axes : FloatList&)
  for _axis in each_enum(EGroundControlAxis GCA_THROTTLE)
    vehicle_input_axes |> push(0.0)

[es(tag=input)]
def vehicle_input_driver_es(info : UpdateStageUpdateInput;
                            input__enabled : bool;
                            vehicle_input__throttle : int;
                            vehicle_input__accel : int;
                            vehicle_input__brake : int;
                            vehicle_input__steer : int;
                            vrSteering : float = 0f;
                            var vehicle_net_phys : VehiclePhysActor&;
                            var vehicle_input_axes : FloatList&)
  let throttle = get_analog_axis_action_state(uint16(vehicle_input__throttle))
  let accel = get_analog_axis_action_state(uint16(vehicle_input__accel))
  let brake = get_analog_axis_action_state(uint16(vehicle_input__brake))
  let steering = get_analog_axis_action_state(uint16(vehicle_input__steer))
  let touchThrottle = get_axis_value(uint16(vehicle_input__throttle))
  let touchSteering = get_axis_value(uint16(vehicle_input__steer))
  let touchThrottleActive = touchThrottle != 0.0
  let touchSteeringActive = touchSteering != 0.0

  assume producedCT = vehicle_net_phys.phys.producedCT
  var throttleValue = 0.0
  if input__enabled && (throttle.bActive || accel.bActive || brake.bActive || touchThrottleActive)
    throttleValue = ((throttle.bActive ? throttle.x : 0.0)
      + (accel.bActive ? accel.x : 0.0)
      - (brake.bActive ? brake.x : 0.0)
      + touchThrottle)
    if !is_equal_float(throttleValue, 0.0, 0.1/* CRUISE_CONTROL_OFF_THRESHOLD */)
      producedCT |> ground_control_state_setCruiseControl(int8(0))
  if steering.bActive || touchSteeringActive
    vehicle_input_axes[int(EGroundControlAxis GCA_STEERING)] = steering.x - touchSteering + vrSteering

  vehicle_input_axes[int(EGroundControlAxis GCA_THROTTLE)] = clamp(throttleValue + vehicle_net_phys.phys.cruiseControlThrottle, -1.0, 1.0)

  let wasThrottle = producedCT |> ground_control_state_getAxisValue(EGroundControlAxis GCA_THROTTLE)
  if throttle.bActive || touchThrottleActive || steering.bActive || touchSteeringActive || vehicle_input_axes[int(EGroundControlAxis GCA_THROTTLE)] != wasThrottle
    for axis in each_enum(EGroundControlAxis GCA_THROTTLE)
      producedCT |> ground_control_state_setAxisValue(axis, vehicle_input_axes[int(axis)])
    producedCT |> ground_control_state_setKeepDrivingDirectionMode(false)

[es(tag=input)]
def vehicle_hand_brake_input_triggered(evt : EventDaInputActionTriggered;
                                       input__enabled : bool;
                                       vehicle_input__handBrake : int;
                                       var vehicle_input_axes : FloatList&)
  if input__enabled && int(evt.action) == vehicle_input__handBrake
    vehicle_input_axes[int(EGroundControlAxis GCA_HAND_BRAKE)] = 1.0

[es(tag=input)]
def vehicle_hand_brake_input_terminated(evt : EventDaInputActionTerminated;
                                        input__enabled : bool;
                                        vehicle_input__handBrake : int;
                                        var vehicle_input_axes : FloatList&)
  if input__enabled && int(evt.action) == vehicle_input__handBrake
    vehicle_input_axes[int(EGroundControlAxis GCA_HAND_BRAKE)] = 0.0
