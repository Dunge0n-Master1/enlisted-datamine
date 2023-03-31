require ecs
require mech
require game.es.events
require game.es.input.input_events
require DagorInput
require TouchInput
require DagorSystem

let TRIGGER_FLAMETHROWER = 4

def init(var mech_input__strafe : int&;
         var vehicle_input__shootSecondary : int&;
         var mech_input__shootFlameThrower : int&)
  mech_input__strafe = int(get_action_handle("Mech.Strafe", TYPEGRP_AXIS))
  vehicle_input__shootSecondary = int(get_action_handle("Mech.ShootSecondary", TYPEGRP_DIGITAL))
  mech_input__shootFlameThrower = int(get_action_handle("Mech.ShootFlamethrower", TYPEGRP_DIGITAL))

  let mechHandle = get_action_set_handle("Mech")
  if int(mechHandle) != int(BAD_ACTION_SET_HANDLE)
    activate_action_set(mechHandle, true)


def reset(var mech_input__strafe : int&;
          var vehicle_input__shootSecondary : int&;
          var mech_input__shootFlameThrower : int&)
  mech_input__strafe = int(BAD_ACTION_HANDLE)
  vehicle_input__shootSecondary = int(BAD_ACTION_HANDLE)
  mech_input__shootFlameThrower = int(BAD_ACTION_HANDLE)

  let mechHandle = get_action_set_handle("Mech")
  if int(mechHandle) != int(BAD_ACTION_SET_HANDLE)
    activate_action_set(mechHandle, false)

def get_action_state_or(action : uint16; default_value : bool)
  let isTouchPressed = is_button_pressed(action)
  let state = get_digital_action_state(action)
  let isActive = state.bActive || isTouchPressed
  return isActive ? (state.bState || isTouchPressed) : default_value

[es(tag=input, REQUIRE=walker_net_phys, on_event=ParallelUpdateFrameDelayed)]
def mech_flamethrower_input_triggered(evt : Event;
                                      input__enabled : bool;
                                      turret_control__gunEids : EidList;
                                      mech_input__shootFlameThrower : int)
  if !input__enabled
    return

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__triggerGroup : int;
                                                     var turret_input__shootFlag : bool&)
      if turret__triggerGroup == TRIGGER_FLAMETHROWER
        turret_input__shootFlag = get_action_state_or(uint16(mech_input__shootFlameThrower), turret_input__shootFlag)

[es(tag=input, REQUIRE=walker_net_phys, on_appear, after=vehicle_turret_input_appear)]
def mech_input_appear(evt : Event;
                      var mech_input__strafe : int&;
                      var vehicle_input__shootSecondary : int&;
                      var mech_input__shootFlameThrower : int&)
  init(mech_input__strafe, vehicle_input__shootSecondary, mech_input__shootFlameThrower)

[es(tag=input, REQUIRE=walker_net_phys, on_disappear, after=vehicle_turret_input_disappear)]
def mech_input_disappear(evt : Event;
                         var mech_input__strafe : int&;
                         var vehicle_input__shootSecondary : int&;
                         var mech_input__shootFlameThrower : int&)
  reset(mech_input__strafe, vehicle_input__shootSecondary, mech_input__shootFlameThrower)

[es(tag=input, REQUIRE=walker_net_phys, after=vehicle_turret_input_init_reset)]
def mech_input_init_reset(evt : EventDaInputInit;
                          var mech_input__strafe : int&;
                          var vehicle_input__shootSecondary : int&;
                          var mech_input__shootFlameThrower : int&)
  if evt.init
    init(mech_input__strafe, vehicle_input__shootSecondary, mech_input__shootFlameThrower)
  else
    reset(mech_input__strafe, vehicle_input__shootSecondary, mech_input__shootFlameThrower)

[es(tag=input)]
def mech_input_driver_es(info : UpdateStageUpdateInput;
                         input__enabled : bool;
                         vehicle_input__throttle : int;
                         vehicle_input__steer : int;
                         mech_input__strafe : int;
                         var walker_net_phys : WalkerPhysActor&)
  if !input__enabled
    return
  walker_net_phys.phys.producedCT.throttle = get_analog_axis_action_state(uint16(vehicle_input__throttle)).x

  walker_net_phys.phys.producedCT.steering = get_analog_axis_action_state(uint16(vehicle_input__steer)).x
  if walker_net_phys.phys.currentState.throttle < 0.f
    walker_net_phys.phys.producedCT.steering *= -1.

  walker_net_phys.phys.producedCT.strafe = get_analog_axis_action_state(uint16(mech_input__strafe)).x

