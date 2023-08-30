require ecs
require DngNet
require CollRes
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
require game.es.inventory_drop_common
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
    pickup_item2(eid, item_eid)

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
  pickup_item_ex2(eid, itemEid, evt.usefulOnly)


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

[es(tag=server, REQUIRE=human_inventory)]
def human_pickup_item_request_es_event_handler(evt : HumanPickupItemRequest; eid : EntityId)
  pickup_item_impl2(eid, evt.itemEid, evt.usefulOnly)


[es(on_appear)]
def drop_item_cb(evt : Event;
                 eid : EntityId;
                 drop_item_cb__lootCleanupTime : float;
                 drop_item_cb__modTemplates : StringList)
  if empty(drop_item_cb__modTemplates)
    if drop_item_cb__lootCleanupTime >= 0.f
      eid |> sendEvent([[CmdBodyCleanup time=drop_item_cb__lootCleanupTime]])
  else
    for tmpl, i in drop_item_cb__modTemplates, range(length(drop_item_cb__modTemplates))
      let isLast = i == (length(drop_item_cb__modTemplates) - 1)
      let modTemplate = string(tmpl) |> add_sub_template_name("item_mod_creation_cb")
      createEntity(modTemplate) <| $(var init)
        init |> set("item_mod_creation_cb__lootCleanupTime", drop_item_cb__lootCleanupTime)
        init |> set("item_mod_creation_cb__isLast", isLast)
        init |> set("slot_attach__attachedTo", eid)
  removeSubTemplate(eid, "drop_item_cb")


[es(on_appear)]
def item_mod_creation_cb(evt : Event;
                         eid : EntityId;
                         slot_attach__attachedTo : EntityId;
                         item_mod_creation_cb__lootCleanupTime : float;
                         item_mod_creation_cb__isLast : bool;
                         gunAttachable__slotName : string;
                         var slot_attach__slotId : int&)
  slot_attach__slotId = animchar_getSlotId(gunAttachable__slotName)
  if item_mod_creation_cb__lootCleanupTime >= 0.f
    if item_mod_creation_cb__isLast
      slot_attach__attachedTo |> sendEvent([[CmdBodyCleanup time=item_mod_creation_cb__lootCleanupTime]])
    eid |> sendEvent([[CmdBodyCleanup time=item_mod_creation_cb__lootCleanupTime]])
  removeSubTemplate(eid, "item_mod_creation_cb")


[es(tag=server, REQUIRE=human_inventory)]
def human_inventory_on_drop_request(evt : HumanDropItemRequest;
                                    eid : EntityId)
  drop_item_from_cont2(eid, evt.itemEid)


[es(tag=server, REQUIRE=human_inventory)]
def human_inventory_on_stop_use_item_request(evt : HumanStopUseItemRequest;
                                             eid : EntityId)
  stop_use_item_impl(eid)


[es(tag=server, REQUIRE=human_inventory)]
def human_inventory_on_drop_gear_request(evt : HumanDropGearRequest;
                                         eid : EntityId)
  drop_gear_from_slot_impl(eid, evt.slotName)


[es(tag=server, REQUIRE=human_inventory)]
def human_inventory_on_pickup_gear_request(evt : HumanPickupGearRequest;
                                           eid : EntityId)
  pickup_item_to_gear_slot_impl(eid, evt.itemEid, evt.slotName)


[es(tag=server, no_order)]
def item_unlimited_cont_dropper(info : UpdateStageInfoAct;
                                eid : EntityId;
                                transform : float3x4;
                                collres : CollisionResource;
                                item_drop_timer__delay : float;
                                startDropTime : float;
                                var unlimitedItemContainer : StringList;
                                var item_drop_timer__last : float&;
                                genItemRadius : float = 0.4f;
                                genItemSpotRise : float = 1.f;
                                container__dropItemRadius : float = 1.0f)
  if info.curTime < item_drop_timer__last + item_drop_timer__delay || info.curTime < startDropTime
    return
  item_drop_timer__last = info.curTime

  if !empty(unlimitedItemContainer)
    drop_item_from_container(eid, string(unlimitedItemContainer[0]), transform, collres, genItemRadius, genItemSpotRise,
                             container__dropItemRadius)
    unlimitedItemContainer |> erase(0)

  if empty(unlimitedItemContainer)
    let newTempl = remove_sub_template_name(getEntityTemplateName(eid), "item_drop_timer")
    remote_recreate_entity_from(eid, newTempl)
