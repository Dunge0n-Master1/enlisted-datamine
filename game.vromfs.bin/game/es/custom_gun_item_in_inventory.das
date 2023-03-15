require ecs
require EnlistedNet
require game.es.events
require ecs.common
require EnlistedHuman
require HumanPhys
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require enlisted.events_enlisted

[es(tag=server, on_appear, on_event=CmdReinitWeapons, after=(human_weap_created_server_es, human_weap_reinit_guns_es), track=itemContainer)]
def custom_inventory_slot_init(evt : Event;
                               eid : EntityId;
                               itemContainer : EidList;
                               human_net_phys : HumanActor;
                               var currentInventoryGunIdx : int&;
                               var inventoryGunsItemsEids : ecs::EidList;
                               var human_weap__gunEids : ecs::EidList)
  var newInventoryGunsItemsEids : array<EntityId>
  for itemEid in itemContainer
    if has(itemEid, "specialWeapItem")
      push(newInventoryGunsItemsEids, itemEid)
      query(itemEid) <| $ [es] (var gun__owner : EntityId&)
        gun__owner = eid

      if find_index(inventoryGunsItemsEids, itemEid) < 0
        sendEvent(eid, [[EventInventorySpecialItemAdded itemEid=itemEid]])

  clear(inventoryGunsItemsEids)
  for itemEid in newInventoryGunsItemsEids
    push(inventoryGunsItemsEids, itemEid)

  let customInventoryWeapon = human_weap__gunEids[int(HUWeaponSlots EWS_SPECIAL)]
  let idxInContainer = find_index(inventoryGunsItemsEids, customInventoryWeapon)

  if !!customInventoryWeapon && idxInContainer != -1
    currentInventoryGunIdx = idxInContainer
    return
  currentInventoryGunIdx = -1
  if length(inventoryGunsItemsEids) > 0
    currentInventoryGunIdx = 0
    let curSlot = human_net_phys.phys.currentState.weapEquipState.curSlot
    if curSlot == HUWeaponSlots EWS_SPECIAL
      currentInventoryGunIdx = -1
      send_net_event(eid, [[CmdNextSpecialGun]])
    else
      human_weap__gunEids[int(HUWeaponSlots EWS_SPECIAL)] = inventoryGunsItemsEids[currentInventoryGunIdx]

[es(tag=gameClient, track=inventoryGunsItemsEids)]
def custom_inventory_slot_empty_es(evt : Event;
                                   human_input__weaponSlotCount : int;
                                   var human_net_phys : HumanActor&;
                                   human_weap__gunEids : ecs::EidList;
                                   inventoryGunsItemsEids : EidList)
  assume ct = human_net_phys.phys.producedCT
  if ct.chosenWeapon != HUWeaponSlots EWS_SPECIAL || length(inventoryGunsItemsEids) > 0
    return
  for i in range(0, human_input__weaponSlotCount)
    let weapon = human_weap__gunEids[i]
    if !!weapon
      set_chosen_weapon(ct, HUWeaponSlots(i))
      return

def is_anim_progress_valid_to_change_weapon(human_net_phys : HumanActor)
  let curSlot = human_net_phys.phys.currentState.weapEquipState.curSlot
  let nextSlot = human_net_phys.phys.currentState.weapEquipState.nextSlot
  if curSlot != HUWeaponSlots EWS_SPECIAL || nextSlot != HUWeaponSlots EWS_SPECIAL
    return false
  let prevStateProgress = human_net_phys.phys.previousState.weapEquipState.progress
  let curStateProgress = human_net_phys.phys.currentState.weapEquipState.progress
  let curState = human_net_phys.phys.currentState.weapEquipState.curState
  if curStateProgress < prevStateProgress && curState == HUWeaponEquipState EES_EQUIPING
    return true
  return false

[es(after=next_weapon_item_request_es)]
def device_animation_equip_special(info : ParallelUpdateFrameDelayed;
                                   eid : EntityId;
                                   action__running : bool;
                                   human_net_phys : HumanActor;
                                   human_weap__currentGunEid : EntityId;
                                   currentInventoryGunIdx : int;
                                   inventoryGunsItemsEids : ecs::EidList)
  let isGunIdxValid = currentInventoryGunIdx >= 0 && currentInventoryGunIdx < length(inventoryGunsItemsEids)
  if !isGunIdxValid || action__running
    return
  let nextItemGunEid = inventoryGunsItemsEids[currentInventoryGunIdx]
  if is_anim_progress_valid_to_change_weapon(human_net_phys)
    sendEventImmediate(human_weap__currentGunEid, [[CmdWeapAttach toEid=eid, isAttached=false, slotId=int(HUWeaponSlots EWS_SPECIAL)]])
    setOptional(human_weap__currentGunEid, "animchar_render__enabled", false)
    sendEventImmediate(nextItemGunEid, [[CmdWeapAttach toEid=eid, isAttached=true, slotId=int(HUWeaponSlots EWS_SPECIAL)]])
    setOptional(nextItemGunEid, "animchar_render__enabled", true)

[es(after=next_weapon_item_request_es)]
def device_update_equip_special(info : ParallelUpdateFrameDelayed;
                                action__running : bool;
                                human_net_phys : HumanActor;
                                currentInventoryGunIdx : int;
                                inventoryGunsItemsEids : ecs::EidList;
                                var human_weap__gunEids : ecs::EidList)
  let isGunIdxValid = currentInventoryGunIdx >= 0 && currentInventoryGunIdx < length(inventoryGunsItemsEids)
  if !isGunIdxValid || action__running
    return
  let hasItemInSpecialSlot = !!human_weap__gunEids[int(HUWeaponSlots EWS_SPECIAL)]
  let isSpecialSlotChoosen = human_net_phys.phys.currentState.weapEquipState.curSlot == HUWeaponSlots EWS_SPECIAL
  if is_anim_progress_valid_to_change_weapon(human_net_phys) || (!hasItemInSpecialSlot && !isSpecialSlotChoosen)
    let nextItemGunEid = inventoryGunsItemsEids[currentInventoryGunIdx]
    human_weap__gunEids[int(HUWeaponSlots EWS_SPECIAL)] = nextItemGunEid

[es(track=(currentInventoryGunIdx, inventoryGunsItemsEids, action__running))]
def change_gun_in_custom_slot(evt : Event;
                              action__running : bool;
                              currentInventoryGunIdx : int;
                              human_weap__currentGunEid : EntityId;
                              inventoryGunsItemsEids : ecs::EidList;
                              var human_net_phys : HumanActor&)
  if currentInventoryGunIdx < 0 || action__running
    return
  let curSlot = human_net_phys.phys.currentState.weapEquipState.curSlot
  if curSlot != HUWeaponSlots EWS_SPECIAL || human_weap__currentGunEid == inventoryGunsItemsEids[currentInventoryGunIdx]
    return
  reset_weapon_state(human_net_phys.phys)

[es(on_event=CmdNextSpecialGun, tag=server)]
def next_weapon_item_request_es(evt : Event;
                                var currentInventoryGunIdx : int&;
                                var forcedNextInventoryGunEid : EntityId&;
                                inventoryGunsItemsEids : ecs::EidList)
  if length(inventoryGunsItemsEids) > 0
    let forcedGunIdx = find_index(inventoryGunsItemsEids, forcedNextInventoryGunEid)
    if forcedGunIdx > -1
      currentInventoryGunIdx = forcedGunIdx
    else
      currentInventoryGunIdx = (currentInventoryGunIdx + 1) % length(inventoryGunsItemsEids)
    forcedNextInventoryGunEid = INVALID_ENTITY_ID