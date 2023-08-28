require ecs
require game.es.input.input_events
require DagorInput
require enlisted.events_enlisted


def init(var vehicle_input__prevCockpitView : int&; var vehicle_input__nextCockpitView : int&)
  vehicle_input__prevCockpitView = int(get_action_handle("Vehicle.PrevCockpitView", TYPEGRP_DIGITAL))
  vehicle_input__nextCockpitView = int(get_action_handle("Vehicle.NextCockpitView", TYPEGRP_DIGITAL))


def reset(var vehicle_input__prevCockpitView : int&; var vehicle_input__nextCockpitView : int&)
  vehicle_input__prevCockpitView = int(BAD_ACTION_HANDLE)
  vehicle_input__nextCockpitView = int(BAD_ACTION_HANDLE)


[es(tag=input, on_appear)]
def vehicle_cockpit_input_appear(evt : Event; var vehicle_input__prevCockpitView : int&; var vehicle_input__nextCockpitView : int&)
  init(vehicle_input__prevCockpitView, vehicle_input__nextCockpitView)

[es(tag=input, on_disappear)]
def vehicle_cockpit_input_disappear(evt : Event; var vehicle_input__prevCockpitView : int&; var vehicle_input__nextCockpitView : int&)
  reset(vehicle_input__prevCockpitView, vehicle_input__nextCockpitView)

[es(tag=input)]
def vehicle_cockpit_input_init_reset(evt : EventDaInputInit; var vehicle_input__prevCockpitView : int&; var vehicle_input__nextCockpitView : int&)
  if evt.init
    init(vehicle_input__prevCockpitView, vehicle_input__nextCockpitView)
  else
    reset(vehicle_input__prevCockpitView, vehicle_input__nextCockpitView)


[es(tag=input)]
def vehicle_cockpit_view_input_es(evt : EventDaInputActionTerminated;
                                  eid : EntityId;
                                  input__enabled : bool;
                                  vehicle_input__prevCockpitView : int;
                                  vehicle_input__nextCockpitView : int)
  if !input__enabled
    return
  find_query <| $ [es] (cockpit__vehicleEid : EntityId;
                        cockpit__slitNodes : IntList;
                        cockpit__cameraTime : float;
                        cockpit__currentSlit : int;
                        var cockpit__prevSlit : int&;
                        var cockpit__nextSlit : int&)
    if eid != cockpit__vehicleEid || cockpit__cameraTime < 1.0
      return false
    let viewsCount = length(cockpit__slitNodes)
    if viewsCount <= 0
      return true
    if int(evt.action) == vehicle_input__nextCockpitView
      cockpit__prevSlit = cockpit__currentSlit
      cockpit__nextSlit = (cockpit__currentSlit + 1) % viewsCount
    elif int(evt.action) == vehicle_input__prevCockpitView
      cockpit__prevSlit = cockpit__currentSlit
      cockpit__nextSlit = ((cockpit__currentSlit + viewsCount) - 1) % viewsCount
    return true
