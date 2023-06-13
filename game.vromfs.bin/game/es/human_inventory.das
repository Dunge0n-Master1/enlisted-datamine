require ecs
require DngNet
require inventory
require ecs.common
require DagorSystem
require DngHuman
require HumanPhys
require DagorMath
require DagorMathUtils
require AnimV20
require game.es.action_common
require game.es.inventory_common
require common_shooter.es.human_weap_common
require game.es.events
require game.events_game
require common_shooter.events_common_shooter

[es(tag=server, on_appear)]
def inventory_item_push_es(evt : Event; eid : EntityId; item__ownerEid : EntityId)
  query(item__ownerEid) <| $ [es] (var itemContainer : EidList)
    if find_index(itemContainer, eid) == -1
      push(itemContainer, eid)

[es(tag=server, on_appear)]
def set_armor_pickup_score(evt : Event; eid : EntityId; var item__pickupScore : float&; item__armorAmount : float)
  if item__pickupScore < 0.0
    item__pickupScore = item__armorAmount
  else
    logerr("item {getEntityTemplateName(eid)} has multiple pickupScore sources")

[es(tag=server, on_disappear, on_event=(EventEntityDied))]
def human_inventory_on_death(evt : Event; eid, human_inventory__entityToUse : EntityId)
  if human_inventory__entityToUse != INVALID_ENTITY_ID
    sendEventImmediate(eid, [[EventInterruptItemUse]])


[es(tag=server, after=before_human_inventory_use_update)]
def human_inventory_server_es(info : UpdateStageInfoAct;
                              eid : EntityId;
                              human_inventory__entityUseEnd : float;
                              var human_inventory__entityToUse : EntityId&;
                              human_inventory__targetToUse : EntityId;
                              var itemContainer : EidList&)
  if !human_inventory__entityToUse
    return

  if !(info.curTime > human_inventory__entityUseEnd && info.curTime - info.dt <= human_inventory__entityUseEnd)
    return

  var needRemove = true
  query(human_inventory__entityToUse) <| $ [es] (var item__useCount : int&) { needRemove = --item__useCount <= 0; }

  if !needRemove
    sendEventImmediate(human_inventory__entityToUse, [[EventOnLootItemUsed target=human_inventory__targetToUse]])
    sendEventImmediate(eid, [[EventOnLootUse itemEid=human_inventory__entityToUse]])
    human_inventory__entityToUse = INVALID_ENTITY_ID

  elif remove_item_from_cont(human_inventory__entityToUse, itemContainer)
    sendEventImmediate(human_inventory__entityToUse, [[EventOnLootItemUsed target=human_inventory__targetToUse]])
    sendEventImmediate(eid, [[EventOnLootUse itemEid=human_inventory__entityToUse]])
    destroyEntity(human_inventory__entityToUse)

  sendEventImmediate(eid, [[EventInterruptItemUse]])


[es(tag=server, on_appear)]
def item_container_init_es(evt : Event; eid : EntityId; var human_inventory__initialItems : ecs::Object)
  let onCreate <- @ <| (item_eid : EntityId)
    inventory::pickup_item(eid, item_eid)

  for item in human_inventory__initialItems
    let itemTemplate = item.key
    let itemCount = get_int(item.value) ?? 0
    if itemTemplate != ""
      for _i in range(0, itemCount)
        createEntity(itemTemplate, onCreate, $ [unused_argument(_)] (var _ : ComponentsInitializer) {})

  clear(human_inventory__initialItems)

[es(REQUIRE=human_inventory)]
def human_inventory_pickup_es(evt : CmdInventoryPickup; eid : EntityId)
  let itemEid = evt.itemEid
  run_action(eid, "pickup")
  if has(itemEid, "gunAttachable")
    if try_pickup_item(eid, itemEid) && can_pickup_item(itemEid, eid)
      sendEvent(eid, [[EventOnLootPickup itemEid=itemEid]])
    send_net_event(eid, [[CmdInventoryPickupGunMod item=itemEid]])
    return
  pickup_item_ex(eid, itemEid, evt.usefulOnly)


[es(REQUIRE=(human_inventory, human_weap))]
def human_inventory_drop_gun_es_event_handler(evt : CmdInventoryDropGun; eid : EntityId)
  if evt.slotId < 0
    return
  drop_weap_from_slot2(eid, get_human_weapon_slot_name(evt.slotId))


[es(tag=server, REQUIRE=human_inventory)]
def human_drop_weap_request_es_event_handler(evt : HumanDropWeapRequest; eid : EntityId)
  drop_weap_from_slot_impl2(eid, evt.slotId, true, false)


[es(tag=server, REQUIRE=human_inventory)]
def human_pickup_weap_request_es_event_handler(evt : HumanPickupWeapRequest; eid : EntityId)
  pickup_item_to_weap_slot_impl2(eid, evt.itemEid, evt.slotId)


[es(tag=server, REQUIRE=human_inventory)]
def human_install_item_on_weap_request_es_event_handler(evt : HumanInstallItemOnWeapRequest; eid : EntityId)
  install_item_on_weap_impl2(eid, evt.itemEid, evt.slotId, evt.slotName)


[es(tag=server, REQUIRE=human_inventory)]
def human_pickup_and_install_item_on_weap_request_es_event_handler(evt : HumanPickupAndInstallItemOnWeapRequest; eid : EntityId)
  pickup_and_install_item_on_weap_impl2(eid, evt.itemEid, evt.slotId, evt.slotName)


[es(tag=server, REQUIRE=human_inventory)]
def human_remove_item_from_weap_request_es_event_handler(evt : HumanRemoveItemFromWeapRequest; eid : EntityId)
  remove_item_from_weap_impl2(eid, evt.slotId, evt.slotName, evt.toGround)


[es(tag=server, REQUIRE=human_inventory)]
def human_swap_weap_request_es_event_handler(evt : HumanSwapWeapRequest; eid : EntityId)
  swap_weapons_in_slots2(eid, evt.fromSlotId, evt.toSlotId)


[es(tag=server, REQUIRE=human_inventory)]
def human_swap_weapon_mods_request_es_event_handler(evt : HumanSwapWeaponModsRequest; eid : EntityId)
  swap_weapon_mods_impl2(eid, evt.fromSlotId, evt.fromWeapModSlot, evt.toSlotId, evt.toWeapModSlot)
