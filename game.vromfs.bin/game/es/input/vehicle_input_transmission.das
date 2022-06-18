require ecs
require game.es.input.input_events
require DagorInput
require vehicle


def init(var vehicle_input__nextGear : int&;
         var vehicle_input__prevGear : int&;
         var vehicle_input__neutralGear : int&;
         var vehicle_input__reverseGear : int&;
         var vehicle_input__automaticTransmission : int&)
  vehicle_input__nextGear              = int(get_action_handle("Vehicle.NextGear", TYPEGRP_DIGITAL))
  vehicle_input__prevGear              = int(get_action_handle("Vehicle.PrevGear", TYPEGRP_DIGITAL))
  vehicle_input__neutralGear           = int(get_action_handle("Vehicle.NeutralGear", TYPEGRP_DIGITAL))
  vehicle_input__reverseGear           = int(get_action_handle("Vehicle.ReverseGear", TYPEGRP_DIGITAL))
  vehicle_input__automaticTransmission = int(get_action_handle("Vehicle.AutomaticTransmission", TYPEGRP_DIGITAL))


def reset(var vehicle_input__nextGear : int&;
          var vehicle_input__prevGear : int&;
          var vehicle_input__neutralGear : int&;
          var vehicle_input__reverseGear : int&;
          var vehicle_input__automaticTransmission : int&)
  vehicle_input__nextGear              = int(BAD_ACTION_HANDLE)
  vehicle_input__prevGear              = int(BAD_ACTION_HANDLE)
  vehicle_input__neutralGear           = int(BAD_ACTION_HANDLE)
  vehicle_input__reverseGear           = int(BAD_ACTION_HANDLE)
  vehicle_input__automaticTransmission = int(BAD_ACTION_HANDLE)


[es(tag=input, on_appear)]
def vehicle_transmission_input_appear(evt : Event;
                                      var vehicle_input__nextGear : int&;
                                      var vehicle_input__prevGear : int&;
                                      var vehicle_input__neutralGear : int&;
                                      var vehicle_input__reverseGear : int&;
                                      var vehicle_input__automaticTransmission : int&)
  init(vehicle_input__nextGear, vehicle_input__prevGear, vehicle_input__neutralGear, vehicle_input__reverseGear, vehicle_input__automaticTransmission)

[es(tag=input, on_disappear)]
def vehicle_transmission_input_disappear(evt : Event;
                                         var vehicle_input__nextGear : int&;
                                         var vehicle_input__prevGear : int&;
                                         var vehicle_input__neutralGear : int&;
                                         var vehicle_input__reverseGear : int&;
                                         var vehicle_input__automaticTransmission : int&)
  reset(vehicle_input__nextGear, vehicle_input__prevGear, vehicle_input__neutralGear, vehicle_input__reverseGear, vehicle_input__automaticTransmission)

[es(tag=input)]
def vehicle_transmission_input_init_reset(evt : EventDaInputInit;
                                          var vehicle_input__nextGear : int&;
                                          var vehicle_input__prevGear : int&;
                                          var vehicle_input__neutralGear : int&;
                                          var vehicle_input__reverseGear : int&;
                                          var vehicle_input__automaticTransmission : int&)
  if evt.init
    init(vehicle_input__nextGear, vehicle_input__prevGear, vehicle_input__neutralGear, vehicle_input__reverseGear, vehicle_input__automaticTransmission)
  else
    reset(vehicle_input__nextGear, vehicle_input__prevGear, vehicle_input__neutralGear, vehicle_input__reverseGear, vehicle_input__automaticTransmission)


[es(tag=input)]
def vehicle_transmission_input_es(evt : EventDaInputActionTerminated;
                                  input__enabled : bool;
                                  vehicle_input__nextGear : int;
                                  vehicle_input__prevGear : int;
                                  vehicle_input__neutralGear : int;
                                  vehicle_input__reverseGear : int&;
                                  vehicle_input__automaticTransmission : int;
                                  var vehicle_net_phys : VehiclePhysActor&)
  if !input__enabled
    return
  assume phys = vehicle_net_phys.phys
  assume ct = vehicle_net_phys.phys.producedCT

  if int(evt.action) == vehicle_input__nextGear
    ct |> ground_control_state_setWishGear(uint8(int(phys.currentState.currentGear) + 1))
    ct |> ground_control_state_setCruiseControl(int8(int(phys.currentState.cruiseControl) + 1))
  elif int(evt.action) == vehicle_input__prevGear
    ct |> ground_control_state_setWishGear(uint8(int(phys.currentState.currentGear) - 1))
    ct |> ground_control_state_setCruiseControl(int8(int(phys.currentState.cruiseControl) - 1))
  elif int(evt.action) == vehicle_input__neutralGear && !ct.isTransmissionAuto
    ct |> ground_control_state_setWishGear(uint8(phys.neutralGearIndex))
  elif int(evt.action) == vehicle_input__reverseGear && !ct.isTransmissionAuto
    ct |> ground_control_state_setWishGear(uint8(phys.neutralGearIndex - 1))
  elif int(evt.action) == vehicle_input__automaticTransmission
    ct |> ground_control_state_setAutomaticTransmission(!ct.isTransmissionAuto)