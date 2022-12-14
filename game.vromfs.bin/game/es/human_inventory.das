require ecs
require EnlistedNet
require inventory
require ecs.common
require DagorSystem
require EnlistedHuman
require HumanPhys
require DagorMath
require DagorMathUtils
require AnimV20
require game.es.action_common
require game.es.inventory_common
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


[es(tag=server, on_appear)]
def set_inventory_extension_pickup_score(evt : Event; eid : EntityId; var item__pickupScore : float&; item__inventoryExtension : float)
  if item__pickupScore < 0.0
    item__pickupScore = item__inventoryExtension
  else
    logerr("item {getEntityTemplateName(eid)} has multiple pickupScore sources")


[es(tag=server, on_appear)]
def set_pickup_score_by_rarity_es(evt : Event;
                                  eid : EntityId;
                                  var item__pickupScore : float&;
                                  item__rarity : string;
                                  [[shared_comp]] item_rarity__pickupScores : ecs::Object)
  if item__pickupScore < 0.0
    item__pickupScore = get_float(item_rarity__pickupScores[item__rarity]) ?? 0.0
  else
    logerr("item {getEntityTemplateName(eid)} has multiple pickupScore sources")


[es(tag=server, on_appear, track=jetpack__fuel)]
def set_jetpack_fuel_pickup_score(evt : Event; var item__pickupScore : float&; jetpack__fuel : float)
  item__pickupScore = jetpack__fuel


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
                              var itemContainer : EidList&;
                              possessedByPlr : EntityId = INVALID_ENTITY_ID)
  if !human_inventory__entityToUse
    return

  if !(info.curTime > human_inventory__entityUseEnd && info.curTime - info.dt <= human_inventory__entityUseEnd)
    return

  var needRemove = true
  query(human_inventory__entityToUse) <| $ [es] (var item__useCount : int&) { needRemove = --item__useCount <= 0; }

  if !needRemove || has(human_inventory__entityToUse, "canBeUsedOutOfInventory")
    sendEventImmediate(human_inventory__entityToUse, [[EventOnLootItemUsed target=human_inventory__targetToUse]])
    sendEventImmediate(eid, [[EventOnLootUse itemEid=human_inventory__entityToUse]])
    human_inventory__entityToUse = INVALID_ENTITY_ID

  elif remove_item_from_cont(human_inventory__entityToUse, itemContainer)
    sendEventImmediate(human_inventory__entityToUse, [[EventOnLootItemUsed target=human_inventory__targetToUse]])
    sendEventImmediate(eid, [[EventOnLootUse itemEid=human_inventory__entityToUse]])

    if !!possessedByPlr
      sendEvent(possessedByPlr, [[EventPlayerOnLootUse entityToUse=human_inventory__entityToUse]])
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
