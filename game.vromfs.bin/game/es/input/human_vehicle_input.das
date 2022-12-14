require ecs
require strings
require game.es.events
require game.es.binocular_common
require game.es.input.input_events
require game.es.vehicle.vehicle_events
require DagorInput
require HumanPhys
require EnlistedHuman
require common_shooter.es.human_weap_common
require game.es.vehicle.vehicle_seats_common
require game.es.human.human_vehicle_common
require enlisted.events_enlisted
require net
require vehicle
require danetlibs.native_dasevents.main.native_events


def init(human_input__seatCount : int;
         var human_input__seats : IntList&;
         var human_input__seatNext : int&;
         var human_input__driverSeat : int&;
         var human_input__vehicleMaintenance : int&;
         var human_input__toggleHatch : int&;
         var human_input__toggleHoldGunMode : int&)
  if length(human_input__seats) != human_input__seatCount
    human_input__seats |> resize(human_input__seatCount)
  human_input__seatNext            = int(get_action_handle("Human.SeatNext", TYPEGRP_DIGITAL))
  human_input__driverSeat          = int(get_action_handle("Human.DriverSeat", TYPEGRP_DIGITAL))
  human_input__vehicleMaintenance  = int(get_action_handle("Human.VehicleMaintenance", TYPEGRP_DIGITAL))
  human_input__toggleHatch         = int(get_action_handle("Human.ToggleHatch", TYPEGRP_DIGITAL))
  human_input__toggleHoldGunMode     = int(get_action_handle("Human.ToggleHoldGunMode", TYPEGRP_DIGITAL))
  for i in range(0, human_input__seatCount)
    human_input__seats[i]          = int(get_action_handle("Human.Seat" + format("%02d", i + 1), TYPEGRP_DIGITAL))



def reset(human_input__seatCount : int;
          var human_input__seats : IntList&;
          var human_input__seatNext : int&;
          var human_input__driverSeat : int&;
          var human_input__vehicleMaintenance : int&;
          var human_input__toggleHatch : int&;
          var human_input__toggleHoldGunMode : int&)
  if length(human_input__seats) != human_input__seatCount
    human_input__seats |> resize(human_input__seatCount)
  human_input__seatNext            = int(BAD_ACTION_HANDLE)
  human_input__driverSeat          = int(BAD_ACTION_HANDLE)
  human_input__vehicleMaintenance  = int(BAD_ACTION_HANDLE)
  human_input__toggleHatch         = int(BAD_ACTION_HANDLE)
  human_input__toggleHoldGunMode         = int(BAD_ACTION_HANDLE)
  for i in range(0, human_input__seatCount)
    human_input__seats[i]          = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def vehicle_input_appear_es(evt : Event;
                            human_input__seatCount : int;
                            var human_input__seats : IntList&;
                            var human_input__seatNext : int&;
                            var human_input__driverSeat : int&;
                            var human_input__vehicleMaintenance : int&;
                            var human_input__toggleHatch : int&;
                            var human_input__toggleHoldGunMode : int&)
  init(human_input__seatCount, human_input__seats, human_input__seatNext,
       human_input__driverSeat, human_input__vehicleMaintenance, human_input__toggleHatch, human_input__toggleHoldGunMode)

[es(tag=input)]
def human_vehicle_input_es(evt : EventDaInputInit;
                           human_input__seatCount : int;
                           var human_input__seats : IntList&;
                           var human_input__seatNext : int&;
                           var human_input__driverSeat : int&;
                           var human_input__vehicleMaintenance : int&;
                           var human_input__toggleHatch : int&;
                           var human_input__toggleHoldGunMode : int&)
  if evt.init
    init(human_input__seatCount, human_input__seats, human_input__seatNext,
         human_input__driverSeat, human_input__vehicleMaintenance, human_input__toggleHatch, human_input__toggleHoldGunMode)
  else
    reset(human_input__seatCount, human_input__seats, human_input__seatNext,
         human_input__driverSeat, human_input__vehicleMaintenance, human_input__toggleHatch, human_input__toggleHoldGunMode)


[es(tag=input)]
def human_change_seat_input_es(evt : EventDaInputActionTriggered;
                               eid : EntityId;
                               human_vehicle__isHoldingGunPassenger : bool;
                               human_anim__vehicleSelected : EntityId;
                               human_input__seats : IntList;
                               human_input__seatNext : int;
                               human_input__driverSeat : int;
                               isInVehicle : bool;
                               input__enabled : bool)
  if !input__enabled || !isInVehicle || human_vehicle__isHoldingGunPassenger
    return
  let action = int(evt.action)
  for i in range(0, length(human_input__seats))
    if action == human_input__seats[i]
      sendEvent(human_anim__vehicleSelected, [[CmdVehiclePlaceSeat eid=eid, seat=i]])
      return
  if action == human_input__seatNext
    sendEvent(human_anim__vehicleSelected, [[CmdVehiclePlaceNextSeat eid=eid]])
  elif action == human_input__driverSeat
    sendEvent(human_anim__vehicleSelected, [[CmdVehiclePlaceDriverSeat eid=eid]])

[es(tag=input)]
def human_vehicle_maintenance_start_input_es(evt : EventDaInputActionTriggered;
                                             eid : EntityId;
                                             maintenance__target : EntityId;
                                             maintenance__hasTarget : bool;
                                             human_input__vehicleMaintenance : int;
                                             input__enabled : bool)
  if input__enabled && maintenance__hasTarget && int(evt.action) == human_input__vehicleMaintenance
    sendEvent(eid, [[CmdStartMaintenance target=maintenance__target]])

[es(tag=input)]
def human_vehicle_maintenance_stop_input_es(evt : EventDaInputActionTerminated;
                                            eid : EntityId;
                                            maintenance__target : EntityId;
                                            maintenance__hasTarget : bool;
                                            human_input__vehicleMaintenance : int;
                                            input__enabled : bool)
  if input__enabled && maintenance__hasTarget && int(evt.action) == human_input__vehicleMaintenance
    sendEvent(eid, [[CmdStopMaintenance target=maintenance__target]])

[es(tag=input)]
def human_vehicle_toggle_hatch_input_es(evt : EventDaInputActionTriggered;
                                        input__enabled : bool;
                                        human_input__toggleHatch : int;
                                        var human_input__standState : int&)
  if input__enabled  && int(evt.action) == human_input__toggleHatch
    human_input__standState = human_input__standState == int(HumanPhysControlType HCT_CROUCH) ? 0 : int(HumanPhysControlType HCT_CROUCH)

[es(tag=input)]
def human_vehicle_toggle_hold_gun_mode_input_es(evt : EventDaInputActionTriggered;
                                                eid : EntityId;
                                                isInVehicle : bool;
                                                isInVehicleHidden : bool;
                                                input__enabled : bool;
                                                human_binocular__mode : bool;
                                                human_weap__gunEids : EidList;
                                                human_weap__currentGunSlot : int;
                                                human_anim__vehicleSelected : EntityId;
                                                human_input__toggleHoldGunMode : int;
                                                human_vehicle__canHoldWeapon : bool;
                                                var human_net_phys : HumanActor&)
  if !input__enabled || int(evt.action) != human_input__toggleHoldGunMode || !isInVehicle
    return

  var isInCockpit = false
  query(human_anim__vehicleSelected) <| $ [es] (cockpit__eid : EntityId)
    query(cockpit__eid) <| $ [es] (cockpit__isAttached : bool)
      isInCockpit = cockpit__isAttached
  if isInCockpit
    return

  if human_vehicle__canHoldWeapon
    let isHoldGunModeBit = human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_HOLD_GUN_MODE)
    let isEnablingHoldGunMode = !isHoldGunModeBit || human_binocular__mode
    if isEnablingHoldGunMode && !is_gun_slot_allowed_to_hold_gun_in_hatch(human_weap__currentGunSlot)
      switch_to_first_weap_with_ammo(human_weap__gunEids, human_net_phys.phys)

    if human_binocular__mode
      send_net_event(eid, [[CmdSwitchBinocular choosePrevGunSlot=BinocularChooseWeapSlotMode None]])

    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_HOLD_GUN_MODE, isEnablingHoldGunMode)
  else
    var hasSuitableSeatForHoldGunMode = false
    query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
      for seatEid in vehicle_seats__seatEids
        query(seatEid) <| $ [es] (seat__isInHatch : bool;
                                  seat__isPassenger : bool;
                                  seat__availableControls : VehicleControlsState;
                                  seat__isHoldGunModeAllowed : bool;
                                  seats_order__canPlaceManually : bool)
          hasSuitableSeatForHoldGunMode ||= (seats_order__canPlaceManually
                                          && is_hold_gun_mode_allowed(isInVehicle,
                                                                      isInVehicleHidden,
                                                                      seat__isPassenger,
                                                                      seat__isHoldGunModeAllowed,
                                                                      seat__isInHatch,
                                                                      seat__availableControls.canControlTurrets))
    if hasSuitableSeatForHoldGunMode
      sendEvent(eid, [[CmdHeroLogEvent event="hold_gun_mode_disallowed_at_seat", text="hold_gun_mode/disallowed_at_seat"]])
    else
      sendEvent(eid, [[CmdHeroLogEvent event="hold_gun_mode_disallowed_in_vehicle", text="hold_gun_mode/disallowed_in_vehicle"]])

[es(tag=input, track=(possessedByPlr, isInVehicle))]
def human_vehicle_disable_hold_gun_mode_input_es(evt : Event;
                                                 isInVehicle : bool;
                                                 possessedByPlr : EntityId;
                                                 var human_net_phys : HumanActor)
  if !possessedByPlr || !isInVehicle
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_HOLD_GUN_MODE, false)


[es(tag=input, track=human_vehicle__isInHatch, REQUIRE=(hero, human_vehicle__isInHatch))]
def human_vehicle_reset_zoom_input_on_change_hatch_state(evt : Event; human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (vehicle_input__zoomToggle : int)
    reset_digital_action_sticky_toggle(uint16(vehicle_input__zoomToggle))


[es(tag=input, track=human_vehicle__occupiedSeatEid, REQUIRE=(hero, human_vehicle__occupiedSeatEid))]
def human_vehicle_reset_aim_input_on_change_seat(evt : Event; human_input__aim1 : int)
  reset_digital_action_sticky_toggle(uint16(human_input__aim1))


[es(tag=input)]
def human_vehicle_maintenance_reset_toggle_on_interrupting(evt : CmdStopMaintenance; human_input__vehicleMaintenance : int)
  reset_digital_action_sticky_toggle(uint16(human_input__vehicleMaintenance))
