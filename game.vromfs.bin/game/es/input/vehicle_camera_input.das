require ecs
require DagorInput
require game.es.input.input_events
require game.es.input.input_common

def init(var vehicle_input__zoomToggle : int&;
         var vehicle_input__zoom : int&)
  vehicle_input__zoomToggle      = int(get_action_handle("Vehicle.ZoomToggle", TYPEGRP_DIGITAL))
  vehicle_input__zoom            = int(get_action_handle("Vehicle.Zoom", TYPEGRP_DIGITAL))

  reset_digital_action_sticky_toggle(uint16(vehicle_input__zoomToggle))


def reset(var vehicle_input__zoomToggle : int&;
          var vehicle_input__zoom : int&)
  vehicle_input__zoomToggle      = int(BAD_ACTION_HANDLE)
  vehicle_input__zoom            = int(BAD_ACTION_HANDLE)

  reset_digital_action_sticky_toggle(uint16(vehicle_input__zoomToggle))

[es(tag=input, on_appear)]
def vehicle_camera_input_appear(evt : Event;
                                var vehicle_input__zoomToggle : int&;
                                var vehicle_input__zoom : int&)
  init(vehicle_input__zoomToggle, vehicle_input__zoom)

[es(tag=input, on_disappear)]
def vehicle_camera_input_disappear(evt : Event;
                                   var vehicle_input__zoomToggle : int&;
                                   var vehicle_input__zoom : int&)
  reset(vehicle_input__zoomToggle, vehicle_input__zoom)

[es(tag=input)]
def vehicle_camera_input_init_reset(evt : EventDaInputInit;
                                    var vehicle_input__zoomToggle : int&;
                                    var vehicle_input__zoom : int&)
  if evt.init
    init(vehicle_input__zoomToggle, vehicle_input__zoom)
  else
    reset(vehicle_input__zoomToggle, vehicle_input__zoom)
