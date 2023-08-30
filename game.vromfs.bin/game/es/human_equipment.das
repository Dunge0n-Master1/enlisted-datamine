require ecs
require perks
require DngNet
require ecs.safe
require inventory
require ecs.common
require DagorSystem
require game.es.events
require game.events_game
require PropsRegistry
require game.es.equipment_common
require game.es.inventory_common


[es(on_appear)]
def attach_vis_entity_cb_handler(evt : Event;
                                 eid : EntityId;
                                 attach_vis_entity_cb__toEid : EntityId;
                                 attach_vis_entity_cb__toSlotName : string)
  let found = query(attach_vis_entity_cb__toEid) <| $ [es] (var human_equipment__slots : Object&)
    human_inventory_item_check_hides(eid, human_equipment__slots, +1)
    var itemObj = human_equipment__slots[attach_vis_entity_cb__toSlotName] |> getRW_ecs_object()
    if itemObj != null
      using() <| $(var newEntities : Array)
        var entities = (*itemObj).entities |> getRW_ecs_array()
        if entities != null
          newEntities |> move(*entities)
        newEntities |> push(eid)
        *itemObj |> set("entities", newEntities)

  if !found
    destroyEntity(eid)


def equip_item_direct_impl(item_eid : EntityId;
                           slot_name : string;
                           allow_reorder_slots : bool;
                           drop_prev_item : bool;
                           eid : EntityId;
                           human_equipment__itemRemap : Object;
                           dm_parts__parts : Object const?;
                           entity_mods__bagsVolumeMult : float const?;
                           var human_equipment__slots : Object&;
                           var human_inventory__capacity : float&;
                           var human_inventory__currentVolume : float&;
                           var dm_parts__partsArmor : FloatList?;
                           var dm_parts__partsArmorMin : FloatList?;
                           var dm_parts__armorItemEids : EidList?;
                           isAlive : bool = true) : bool
  var res = false
  query(eid) <| $ [es] (possessedByPlr : EntityId = INVALID_ENTITY_ID)
    if item_eid != INVALID_ENTITY_ID
      if !doesEntityExist(item_eid) // if we're requested to equip item, but there's no item there - do not even try to equip it.
        return
      if !is_item_for_slot(item_eid, slot_name)
        logerr("Item <{getEntityTemplateName(item_eid)}> is not equippable for slot '{slot_name}'")
        return

      var hasOwner = false
      query(item_eid) <| $ [es] (item__ownerEid : EntityId)
        hasOwner = (item__ownerEid != INVALID_ENTITY_ID)
      if hasOwner
        return

      if allow_reorder_slots
        try_rotate_to_linked_slot(slot_name, human_equipment__slots)

    var itemObj = getRW_ecs_object(human_equipment__slots, slot_name)
    if itemObj == null
      logerr("Cannot find slot '{slot_name}' in equipment for {eid} <{getEntityTemplateName(eid)}>")
      return

    // first unequip current item
    var prevItem = (*itemObj).item ?? INVALID_ENTITY_ID
    if prevItem != INVALID_ENTITY_ID && !doesEntityExist(prevItem)
      prevItem = INVALID_ENTITY_ID
    if (isAlive && has(prevItem, "item__unequipOnlyOnDeath")) || has(prevItem, "item__nonDroppable")
      if isAlive
        sendEvent(eid, [[CmdHeroLogEvent event="attempt_unequip_unequippable", text="hint/unequippable_item"]])
      return

    if prevItem == item_eid
      return

    query(prevItem) <| $ [es] (item__armorAmount : float;
                               item__armoredParts : Array)
      if item__armorAmount > 0.f && dm_parts__parts != null && dm_parts__partsArmor != null
        for part in item__armoredParts
          let partId = get_part_data_node_id(*dm_parts__parts, get_string(part, ""))
          if partId >= 0 && partId < length(*dm_parts__partsArmor)
            (*dm_parts__partsArmor)[partId] = 0.0f
          if dm_parts__partsArmorMin != null && partId >= 0 && partId < length(*dm_parts__partsArmorMin)
            (*dm_parts__partsArmorMin)[partId] = 0.0f
          if dm_parts__armorItemEids != null && partId >= 0 && partId < length(*dm_parts__armorItemEids)
            (*dm_parts__armorItemEids)[partId] = INVALID_ENTITY_ID

    var prevInventoryExtention = 0.f
    var newInventoryExtention = 0.f
    query(prevItem) <| $ [es] (item__inventoryExtension aka prev_item__inventoryExtension : float)
      prevInventoryExtention = prev_item__inventoryExtension
    query(item_eid) <| $ [es] (item__inventoryExtension aka new_item__inventoryExtension : float)
      newInventoryExtention = new_item__inventoryExtension
    if entity_mods__bagsVolumeMult != null
      // round to first decimal digit
      prevInventoryExtention = float(roundi(prevInventoryExtention * (*entity_mods__bagsVolumeMult) * 10.f)) / 10.f
      newInventoryExtention = float(roundi(newInventoryExtention * (*entity_mods__bagsVolumeMult) * 10.f)) / 10.f

    if prevInventoryExtention > 0.f
      let resultingCapacity = human_inventory__capacity - prevInventoryExtention + newInventoryExtention
      if resultingCapacity < human_inventory__currentVolume
        return
      human_inventory__capacity = human_inventory__capacity - prevInventoryExtention

    query(prevItem) <| $ [es] (item__perkName : string)
      if !empty(item__perkName) && check_equpment_allowed(eid, item__perkName)
        let prevPerkPropsId = get_props_id(item__perkName, "entity_mod")
        remove_perk(eid, item__perkName, prevPerkPropsId)

    // drop previous item
    if prevItem != INVALID_ENTITY_ID
      if possessedByPlr != INVALID_ENTITY_ID
        sendEvent(possessedByPlr, [[EventOnEquipmentUnequiped equipmentEid=prevItem]])
      if drop_prev_item
        unequip_entity_item(eid, prevItem)

    var entities = (*itemObj).entities |> getRW_ecs_array()
    if entities != null
      for entity in *entities
        let remEid = entity ?? INVALID_ENTITY_ID
        human_inventory_item_check_hides(remEid, human_equipment__slots, -1)
        destroyEntity(remEid)

      if empty(*entities) && prevItem != INVALID_ENTITY_ID
        human_inventory_item_check_hides(prevItem, human_equipment__slots, -1)
      clear(*entities)

    var newSoundTag = ""
    query(item_eid) <| $ [es] (item__armoredParts : Array const?;
                               item__equipSlots : Object const?;
                               item__soundTag : string = "";
                               item__armorAmount : float = 0.f;
                               item__armorAmountMin : float = 0.f)
      newSoundTag = item__soundTag

      // then equip new item
      if item__armorAmount > 0.f && dm_parts__parts != null && dm_parts__partsArmor != null && item__armoredParts != null
        for part in *item__armoredParts
          let partId = get_part_data_node_id(*dm_parts__parts, get_string(part, ""))
          if partId >= 0 && partId < length(*dm_parts__partsArmor)
            (*dm_parts__partsArmor)[partId] = item__armorAmount
          if dm_parts__partsArmorMin != null && partId >= 0 && partId < length(*dm_parts__partsArmorMin)
            (*dm_parts__partsArmorMin)[partId] = item__armorAmountMin
          if dm_parts__armorItemEids != null && partId >= 0 && partId < length(*dm_parts__armorItemEids)
            (*dm_parts__armorItemEids)[partId] = item_eid

      if item__equipSlots != null
        for slot in *item__equipSlots
          attach_vis_entity(get_string(slot.value, ""), eid, slot_name, slot.key, human_equipment__itemRemap)
      else
        human_inventory_item_check_hides(item_eid, human_equipment__slots, +1)

    *itemObj |> set("soundTag", newSoundTag)

    query(item_eid) <| $ [es] (var item__ownerEid : EntityId&;
                               var slot_attach__attachedTo : EntityId?;
                               item__recreateOnGround : string = "item_in_world";
                               item__recreateInEquipment : string = "base_vis_item";
                               item__perkName : string = "")
      item__ownerEid = eid
      if possessedByPlr != INVALID_ENTITY_ID
        sendEvent(possessedByPlr, [[EventOnEquipmentEquiped equipmentEid=item_eid]])
      let origTemplateName = getEntityTemplateName(item_eid)
      var newTemplateName = origTemplateName
      if !empty(item__recreateOnGround)
        newTemplateName = remove_sub_template_name(newTemplateName, item__recreateOnGround)
      if !empty(item__recreateInEquipment)
        newTemplateName = add_sub_template_name(newTemplateName, item__recreateInEquipment)

      if !empty(newTemplateName) && newTemplateName != origTemplateName
        remote_recreate_entity_from(item_eid, newTemplateName) <| $(init)
          init |> set("slot_attach__attachedTo", eid)
      elif slot_attach__attachedTo != null
        *slot_attach__attachedTo = eid
      else
        logerr("failed to recreate <{getEntityTemplateName(item_eid)}>-<{item__recreateOnGround}> entity {eid}")

      if !empty(item__perkName) && check_equpment_allowed(eid, item__perkName)
        let newPerkPropsId = register_props(item__perkName, "entity_mod")
        add_perk(eid, item__perkName, newPerkPropsId, 1.f)

    check_and_request_enable_flag(prevItem, item_eid, slot_name, human_equipment__slots, eid)
    if newInventoryExtention > 0.f
      human_inventory__capacity = human_inventory__capacity + newInventoryExtention
    *itemObj |> set("item", item_eid)
    res = true

  return res


[es(tag=server)]
def equip_item_direct(eqEvt : CmdEquipItemDirect;
                      eid : EntityId;
                      human_equipment__itemRemap : Object;
                      dm_parts__parts : Object const?;
                      entity_mods__bagsVolumeMult : float const?;
                      var human_equipment__slots : Object&;
                      var human_inventory__capacity : float&;
                      var human_inventory__currentVolume : float&;
                      var dm_parts__partsArmor : FloatList?;
                      var dm_parts__partsArmorMin : FloatList?;
                      var dm_parts__armorItemEids : EidList?;
                      isAlive : bool = true)
  equip_item_direct_impl(eqEvt.itemEid, eqEvt.slot, eqEvt.allowReorderSlots, eqEvt.dropPrevItem, eid,
                         human_equipment__itemRemap, dm_parts__parts, entity_mods__bagsVolumeMult,
                         human_equipment__slots, human_inventory__capacity, human_inventory__currentVolume,
                         dm_parts__partsArmor, dm_parts__partsArmorMin, dm_parts__armorItemEids, isAlive)


[es(tag=server)]
def equip_item(eqEvt : CmdEquipItem;
               eid : EntityId;
               human_equipment__itemRemap : Object;
               dm_parts__parts : Object const?;
               entity_mods__bagsVolumeMult : float const?;
               var human_equipment__slots : Object&;
               var human_inventory__capacity : float&;
               var human_inventory__currentVolume : float&;
               var dm_parts__partsArmor : FloatList?;
               var dm_parts__partsArmorMin : FloatList?;
               var dm_parts__armorItemEids : EidList?;
               isAlive : bool = true)
  if !check_pickup_item_by_uniqueness(eid, eqEvt.itemEid)
    return
  equip_item_direct_impl(eqEvt.itemEid, eqEvt.slotName, false, true, eid,
                         human_equipment__itemRemap, dm_parts__parts, entity_mods__bagsVolumeMult,
                         human_equipment__slots, human_inventory__capacity, human_inventory__currentVolume,
                         dm_parts__partsArmor, dm_parts__partsArmorMin, dm_parts__armorItemEids, isAlive)
