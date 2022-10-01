require ecs
require app
require inventory
require DagorInput
require game.es.events
require game.es.input.input_events
require ForceFeedbackRumble
require game.es.input.input_common
require EnlistedHuman
require HumanPhys
require common_shooter.events_common_shooter
require common_shooter.events_common_shooter

[es(tag=input, after=human_input_es)]
def human_inventory_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                              eid : EntityId;
                                              input__enabled : bool;
                                              human_net_phys : HumanActor;
                                              human_inventory__selectedItem : EntityId;
                                              human_inventory_input__forcedPickup : int;
                                              human_inventory_input__pickup : int;
                                              human_inventory_input__useMedkit : int;
                                              human_inventory_input__dropGun : int;
                                              human_input__lastShootInput : float;
                                              var human_input__lastWeaponChangeInput : float&;
                                              human_inventory__dropsLoot : bool = true;
                                              heal__continuousInput : bool = true;
                                              human_weap__currentGunSlot : int = -1;
                                              human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID)
  if !input__enabled
    return

  let action = int(evt.action)
  let selectedItem = human_inventory__selectedItem
  let isForcedPickup = (action == human_inventory_input__forcedPickup)

  if isForcedPickup || action == human_inventory_input__pickup
    if !doesEntityExist(selectedItem) || has(selectedItem, "disableItemDrop")
      return

    let isForcedOrFastPickup = isForcedPickup || is_fast_pickup_item(eid, selectedItem)
    if isForcedOrFastPickup || is_item_useful(eid, selectedItem)
      // is_item_useful is client-side check, it operates on server-replicated components like "human_xxx", thus,
      // a situation may arise when the player issues two (non-forced) pickups, first pickup is for useful item,
      // so we pick it up, second pickup is useless, but we don't know that yet, since "human_xxx" components haven't
      // been replicated yet, so we think it's useful as well and do another pickup. In order to avoid that we
      // also do is_item_useful check on server and if that fails we don't pick up the item. That only makes sense
      // for non-forced and non-fast pickups.
      let usefulOnly = !isForcedOrFastPickup
      sendEvent(eid, [[CmdInventoryPickup itemEid=selectedItem, usefulOnly=usefulOnly]])
    if is_gamepad_input()
      sendEvent(eid, [[CmdRumble eventName="pickupItem"]])
  elif human_inventory_input__useMedkit == action && heal__continuousInput
    sendEvent(eid, [[CmdMedkitUse]]);
  elif human_inventory_input__dropGun == action
    let atTime = get_sync_time()
    // we're blocking weapon drop right after shoot, so we'll not be able to drop our gun on server before it've processed
    // our shot.
    let isWeaponDropBlocked = (atTime - human_input__lastShootInput < get_interp_delay_time(human_net_phys) ||
                               !human_inventory__dropsLoot)
    if isWeaponDropBlocked || has(human_weap__currentGunEid, "disableItemDrop")
      return

    let curSlot = human_weap__currentGunSlot
    if curSlot < 0 || curSlot == int(HUWeaponSlots EWS_MELEE) || curSlot == int(HUWeaponSlots EWS_GRENADE)
      return
    human_input__lastWeaponChangeInput = atTime
    sendEvent(eid, [[CmdInventoryDropGun slotId=curSlot]])
