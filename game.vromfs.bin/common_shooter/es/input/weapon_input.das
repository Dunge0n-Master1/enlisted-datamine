require app
require EnlistedNet
require ecs
require Gun
require game.es.events
require game.es.input.input_events
require game.es.vehicle.vehicle_seats_common
require DagorInput
require TouchInput
require EnlistedHuman
require HumanPhys
require common_shooter.events_common_shooter

def init(human_input__weaponSlotCount : int;
         var human_input__weapons : IntList&;
         var human_input__weaponNextMain : int&;
         var human_input__weaponNext : int&;
         var human_input__weaponPrevMain : int&;
         var human_input__weaponPrev : int&;
         var human_input__grenadeNext : int&;
         var human_input__weapAmmoToggle : int&;
         var human_input__weapModToggle : int&;
         var human_input__specialItemSlot : int&;
         var human_input__firingModeNext : int&;
         var human_input__shoot : int&)
  if length(human_input__weapons) != human_input__weaponSlotCount
    human_input__weapons |> resize(human_input__weaponSlotCount)
  human_input__weaponNextMain  = int(get_action_handle("Human.WeaponNextMain", TYPEGRP_DIGITAL))
  human_input__weaponNext      = int(get_action_handle("Human.WeaponNext", TYPEGRP_DIGITAL))
  human_input__weaponPrevMain  = int(get_action_handle("Human.WeaponPrevMain", TYPEGRP_DIGITAL))
  human_input__weaponPrev      = int(get_action_handle("Human.WeaponPrev", TYPEGRP_DIGITAL))
  human_input__grenadeNext     = int(get_action_handle("Human.GrenadeNext", TYPEGRP_DIGITAL))
  human_input__weapAmmoToggle   = int(get_action_handle("Human.WeapAmmoToggle", TYPEGRP_DIGITAL))
  human_input__weapModToggle   = int(get_action_handle("Human.WeapModToggle", TYPEGRP_DIGITAL))
  human_input__specialItemSlot  = int(get_action_handle("Human.SpecialItemSlot", TYPEGRP_DIGITAL))
  human_input__firingModeNext  = int(get_action_handle("Human.FiringMode", TYPEGRP_DIGITAL))
  human_input__shoot           = int(get_action_handle("Human.Shoot", TYPEGRP_DIGITAL))
  for i in range(0, human_input__weaponSlotCount)
    human_input__weapons[i] = int(get_action_handle("Human.Weapon{i + 1}", TYPEGRP_DIGITAL))


def reset(human_input__weaponSlotCount : int;
          var human_input__weapons : IntList&;
          var human_input__weaponNextMain : int&;
          var human_input__weaponNext : int&;
          var human_input__weaponPrevMain : int&;
          var human_input__weaponPrev : int&;
          var human_input__grenadeNext : int&;
          var human_input__weapAmmoToggle : int&;
          var human_input__weapModToggle : int&;
          var human_input__specialItemSlot : int&;
          var human_input__firingModeNext : int&;
          var human_input__shoot : int&)
  if length(human_input__weapons) != human_input__weaponSlotCount
    human_input__weapons |> resize(human_input__weaponSlotCount)
  human_input__weaponNextMain  = int(BAD_ACTION_HANDLE)
  human_input__weaponNext      = int(BAD_ACTION_HANDLE)
  human_input__weaponPrevMain  = int(BAD_ACTION_HANDLE)
  human_input__weaponPrev      = int(BAD_ACTION_HANDLE)
  human_input__grenadeNext     = int(BAD_ACTION_HANDLE)
  human_input__weapAmmoToggle  = int(BAD_ACTION_HANDLE)
  human_input__weapModToggle   = int(BAD_ACTION_HANDLE)
  human_input__specialItemSlot = int(BAD_ACTION_HANDLE)
  human_input__firingModeNext  = int(BAD_ACTION_HANDLE)
  human_input__shoot           = int(BAD_ACTION_HANDLE)
  for i in range(0, human_input__weaponSlotCount)
    human_input__weapons[i] = int(BAD_ACTION_HANDLE)


def set_weapon_slot(at_time; eid; slot; var ct : HumanControlState&; var last_change_time : float&)
  if !!eid && ct.chosenWeapon != slot
    set_chosen_weapon(ct, slot)
    last_change_time = at_time


def get_weapon_slot_at(main_weapon; forward; position; limit = HUWeaponSlots EWS_NUM)
  var ret = int(main_weapon)
  ret += forward ? position : -position + int(limit)
  return HUWeaponSlots(ret % int(limit))


def get_main_weapon_slot(current; forward)
  if HUWeaponSlots(current) == HUWeaponSlots EWS_PRIMARY
    return HUWeaponSlots(current)
  return forward ? HUWeaponSlots EWS_SECONDARY : HUWeaponSlots EWS_PRIMARY

[es(tag=input, on_appear)]
def weapon_input_appear_es(evt : Event;
                           human_input__weaponSlotCount : int;
                           var human_input__weapons : IntList&;
                           var human_input__weaponNextMain : int&;
                           var human_input__weaponNext : int&;
                           var human_input__weaponPrevMain : int&;
                           var human_input__weaponPrev : int&;
                           var human_input__grenadeNext : int&;
                           var human_input__weapAmmoToggle : int&;
                           var human_input__weapModToggle : int&;
                           var human_input__specialItemSlot : int&;
                           var human_input__firingModeNext : int&;
                           var human_input__shoot : int&)
  init(human_input__weaponSlotCount, human_input__weapons, human_input__weaponNextMain, human_input__weaponNext,
       human_input__weaponPrevMain, human_input__weaponPrev, human_input__grenadeNext, human_input__weapAmmoToggle,
       human_input__weapModToggle, human_input__specialItemSlot, human_input__firingModeNext, human_input__shoot)

[es(tag=input, on_disappear)]
def weapon_input_disappear_es(evt : Event;
                              human_input__weaponSlotCount : int;
                              var human_input__weapons : IntList&;
                              var human_input__weaponNextMain : int&;
                              var human_input__weaponNext : int&;
                              var human_input__weaponPrevMain : int&;
                              var human_input__weaponPrev : int&;
                              var human_input__grenadeNext : int&;
                              var human_input__weapAmmoToggle : int&;
                              var human_input__weapModToggle : int&;
                              var human_input__specialItemSlot : int&;
                              var human_input__firingModeNext : int&;
                              var human_input__shoot : int&)
  reset(human_input__weaponSlotCount, human_input__weapons, human_input__weaponNextMain, human_input__weaponNext,
        human_input__weaponPrevMain, human_input__weaponPrev, human_input__grenadeNext, human_input__weapAmmoToggle,
        human_input__weapModToggle, human_input__specialItemSlot, human_input__firingModeNext, human_input__shoot)

[es(tag=input)]
def human_weapon_input_es(evt : EventDaInputInit;
                          human_input__weaponSlotCount : int;
                          var human_input__weapons : IntList&;
                          var human_input__weaponNextMain : int&;
                          var human_input__weaponNext : int&;
                          var human_input__weaponPrevMain : int&;
                          var human_input__weaponPrev : int&;
                          var human_input__grenadeNext : int&;
                          var human_input__weapAmmoToggle : int&;
                          var human_input__weapModToggle : int&;
                          var human_input__specialItemSlot : int&;
                          var human_input__firingModeNext : int&;
                          var human_input__shoot : int&)
  if evt.init
    init(human_input__weaponSlotCount, human_input__weapons, human_input__weaponNextMain, human_input__weaponNext,
         human_input__weaponPrevMain, human_input__weaponPrev, human_input__grenadeNext, human_input__weapAmmoToggle,
         human_input__weapModToggle, human_input__specialItemSlot, human_input__firingModeNext, human_input__shoot)
  else
    reset(human_input__weaponSlotCount, human_input__weapons, human_input__weaponNextMain, human_input__weaponNext,
          human_input__weaponPrevMain, human_input__weaponPrev, human_input__grenadeNext, human_input__weapAmmoToggle,
          human_input__weapModToggle, human_input__specialItemSlot, human_input__firingModeNext, human_input__shoot)

[es(tag=input)]
def human_weapon_switch_input_es(evt : EventDaInputActionTriggered;
                                 eid : EntityId;
                                 human_vehicle__isHoldingGunPassenger : bool;
                                 human_weap__weapModActivateFinishTime : float;
                                 human_weap__gunEids : EidList;
                                 human_input__lastShootInput : float;
                                 human_input__weapons : IntList;
                                 human_input__weaponSlotCount : int;
                                 human_input__weaponNext : int;
                                 human_input__weaponPrev : int;
                                 human_input__weaponNextMain : int;
                                 human_input__weaponPrevMain : int;
                                 human_input__grenadeNext : int;
                                 human_input__specialItemSlot : int;
                                 input__enabled : bool;
                                 isInVehicle : bool;
                                 bipod__enabled : bool = false;
                                 var human_net_phys : HumanActor&;
                                 var human_input__lastWeaponChangeInput : float&)
  assume ct = human_net_phys.phys.producedCT
  if !input__enabled || bipod__enabled
    return
  let time = get_sync_time()
  let action = int(evt.action)
  let cur_weap = int(ct.chosenWeapon)
  assume last_change_time = human_input__lastWeaponChangeInput
  // we block weapon switch right after shot, so we'll not be able to switch weapons right after we've made a shot
  // on a client thus effectively not shooting on server.
  if time - human_input__lastShootInput < get_interp_delay_time(human_net_phys)
    return
  if time <= human_weap__weapModActivateFinishTime
    return
  if !isInVehicle || human_vehicle__isHoldingGunPassenger
    for i in range(0, human_input__weaponSlotCount)
      let weapon = human_weap__gunEids[i]
      if !!weapon && action == human_input__weapons[i] && (!human_vehicle__isHoldingGunPassenger || is_gun_slot_allowed_to_hold_gun_in_hatch(i))
        set_weapon_slot(time, weapon, HUWeaponSlots(i), ct, last_change_time)
        return

  if action == human_input__weaponNext || action == human_input__weaponPrev
    let forward = action == human_input__weaponNext
    for i in range(int(HUWeaponSlots EWS_SECONDARY), int(HUWeaponSlots EWS_NUM))
      let slot = get_weapon_slot_at(cur_weap, forward, i)
      let weapon = human_weap__gunEids[int(slot)]
      if !!weapon && slot != (HUWeaponSlots EWS_GRENADE)
        set_weapon_slot(time, weapon, slot, ct, last_change_time)
        return

  elif action == human_input__weaponNextMain || action == human_input__weaponPrevMain
    let forward = action == human_input__weaponNextMain
    let count = int(HUWeaponSlots EWS_SECONDARY) + 1
    let main_weap = get_main_weapon_slot(cur_weap, forward)
    for i in range(1, count + 1)
      let slot = get_weapon_slot_at(main_weap, forward, i, HUWeaponSlots(count))
      let weapon = human_weap__gunEids[int(slot)]
      if !!weapon && slot != HUWeaponSlots(cur_weap)
        set_weapon_slot(time, weapon, slot, ct, last_change_time)
        return

  elif action == human_input__grenadeNext
    sendEvent(eid, [[CmdToggleWishAmmoItemType slot_id=int(HUWeaponSlots EWS_GRENADE)]])

  elif action == human_input__specialItemSlot
    let slot = HUWeaponSlots EWS_SPECIAL
    let weapon = human_weap__gunEids[int(slot)]
    if !!weapon
      if slot != HUWeaponSlots(cur_weap)
        set_weapon_slot(time, weapon, slot, ct, last_change_time)
        return
      else
        send_net_event(eid, [[CmdNextSpecialGun]])

[es(tag=input)]
def human_input_weapon_action_triggered_es(evt : EventDaInputActionTriggered;
                                           eid : EntityId;
                                           human_input__weapAmmoToggle : int;
                                           human_input__weapModToggle : int;
                                           human_input__firingModeNext : int;
                                           human_weap__gunEids : EidList;
                                           human_weap__currentGunSlot : int;
                                           human_input__shoot : int;
                                           human_net_phys : HumanActor;
                                           input__enabled : bool)
  if !input__enabled
    return

  let action = int(evt.action)
  if action == human_input__weapAmmoToggle
    sendEvent(eid, [[CmdToggleWishAmmoItemType slot_id=int(human_net_phys.phys.producedCT.chosenWeapon)]])
  elif action == human_input__weapModToggle
    sendEvent(eid, [[CmdWeapModToggle slotId=int(human_net_phys.phys.producedCT.chosenWeapon)]])
  elif action == human_input__firingModeNext
    let shoot = uint16(human_input__shoot)
    if (is_action_active(shoot) && (get_digital_action_state(shoot).bState || is_button_pressed(shoot)))
      return

    if human_weap__currentGunSlot < 0
      return

    let weaponEid = human_weap__gunEids[human_weap__currentGunSlot]
    query(weaponEid) <| $ [es] (gun : Gun)
      let currentGunSlot = uint8(human_weap__currentGunSlot)
      let wishModeId = gun |> gun_getNextFiringModeIndex()
      send_net_event(eid, [[HumanWeapRequestSwitchFiringMode slotId=currentGunSlot, modeId=wishModeId]])
