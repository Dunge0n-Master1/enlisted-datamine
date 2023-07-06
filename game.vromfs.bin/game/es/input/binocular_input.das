require ecs
require net
require game.es.binocular_common
require game.es.input.input_events
require enlisted.events_enlisted
require DagorInput
require HumanPhys

def init(var binocular_input__use : int&)
  binocular_input__use = int(get_action_handle("Human.UseBinocular", TYPEGRP_DIGITAL))

def reset(var binocular_input__use : int&)
  binocular_input__use = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def binocular_input_appear(evt : Event; var binocular_input__use : int&)
  init(binocular_input__use)

[es(tag=input)]
def binocular_input(evt : EventDaInputInit; var binocular_input__use : int&)
  if evt.init
    init(binocular_input__use)
  else
    reset(binocular_input__use)

[es(tag=input)]
def binocular_input_action_triggered(evt : EventDaInputActionTriggered;
                                     eid : EntityId;
                                     binocular_input__use : int;
                                     human_input__shoot : int;
                                     human_input__weapons : IntList;
                                     human_input__weaponNextMain : int;
                                     human_input__weaponNext : int;
                                     human_input__weaponPrevMain : int;
                                     human_input__weaponPrev : int;
                                     human_input__grenadeNext : int;
                                     human_input__specialItemSlot : int;
                                     human_binocular__mode : bool;
                                     input__enabled : bool)
  if !input__enabled
    return

  let action = int(evt.action)
  let isSwitchingWeapSlotByScrolling = (action == human_input__weaponNextMain
                                     || action == human_input__weaponNext
                                     || action == human_input__weaponPrevMain
                                     || action == human_input__weaponPrev)
  let isSwitchingWeapSlotAction = (action == human_input__weapons[int(HUWeaponSlots EWS_PRIMARY)]
                                || action == human_input__grenadeNext
                                || action == human_input__specialItemSlot)

  if action == binocular_input__use
    sendEvent(eid, [[RequestSwitchBinocular choosePrevGunSlot=BinocularChooseWeapSlotMode ChoosePrevGunSlot]])
  elif human_binocular__mode && action == human_input__shoot
    sendEvent(eid, [[RequestSwitchBinocular choosePrevGunSlot=BinocularChooseWeapSlotMode ChoosePrevGunSlot]])
  elif human_binocular__mode && isSwitchingWeapSlotByScrolling
    sendEvent(eid, [[RequestSwitchBinocular choosePrevGunSlot=BinocularChooseWeapSlotMode ChooseFirstWeapWithAmmo]])
  elif human_binocular__mode && isSwitchingWeapSlotAction
    sendEvent(eid, [[RequestSwitchBinocular choosePrevGunSlot=BinocularChooseWeapSlotMode ChooseFirstWeapWithAmmo]])

[es(tag=input)]
def binocular_switch_request(evt : RequestSwitchBinocular; eid : EntityId)
  send_net_event(eid, [[CmdSwitchBinocular choosePrevGunSlot=evt.choosePrevGunSlot]])


[es(tag=input)]
def binocular_disable_on_toggle_hatch(evt : EventDaInputActionTriggered;
                                      eid : EntityId;
                                      input__enabled : bool;
                                      human_binocular__mode : bool;
                                      human_input__toggleHatch : int;
                                      human_vehicle__occupiedSeatEid : EntityId)
  let hasHatch = get_bool(human_vehicle__occupiedSeatEid, "seats_hatch_nodes__isValid") ?? false
  if input__enabled && int(evt.action) == human_input__toggleHatch && hasHatch && human_binocular__mode
    send_net_event(eid, [[CmdSwitchBinocular choosePrevGunSlot=BinocularChooseWeapSlotMode ChoosePrevGunSlot]])
