require ecs

def unhide_crew_equipment(var hidden_equipment_items_in_vehicle : ecs::EidList)
  for equipmentEid in hidden_equipment_items_in_vehicle
    ecs::query(equipmentEid) <| $ [es] (var slot_attach__visible : bool&)
      slot_attach__visible = true
  clear(hidden_equipment_items_in_vehicle)

[es(tag=gameClient, on_appear, on_event=(EventEntityCreated, EventEntityDied), track=(human_anim__vehicleSelected, isTpsView, bindedCamera), REQUIRE=watchedByPlr)]
def crew_quipment_hider_in_cockpit(evt : Event;
                                   isAlive : bool;
                                   isTpsView : bool;
                                   bindedCamera : EntityId;
                                   human_anim__vehicleSelected : EntityId;
                                   human_equipment__slots : ecs::Object;
                                   var hidden_equipment_items_in_vehicle : ecs::EidList)
  if !human_anim__vehicleSelected || !isAlive || isTpsView
    unhide_crew_equipment(hidden_equipment_items_in_vehicle)
    return
  if !(get_bool(bindedCamera, "isHeroCockpitCam") ?? false)
    return
  ecs::query(human_anim__vehicleSelected) <| $ [es] (hide_hero_equipment_slots_in_cockpit : StringList)
    for slotName in hide_hero_equipment_slots_in_cockpit
      let it = human_equipment__slots[string(slotName)]
      if it == null
        continue
      let slot = get_ecs_object(*it)
      let itemEid = get_Eid(slot, "item") ?? INVALID_ENTITY_ID
      ecs::query(itemEid) <| $ [es] (var slot_attach__visible : bool&)
        if !slot_attach__visible
          return
        slot_attach__visible = false
        push(hidden_equipment_items_in_vehicle, itemEid)

// If this human is no longer hero - unhide his equipment.
[es(tag=gameClient, on_event=EventComponentsDisappear, REQUIRE=hero)]
def crew_quipment_unhider_in_cockpit(evt : Event; var hidden_equipment_items_in_vehicle : ecs::EidList)
  unhide_crew_equipment(hidden_equipment_items_in_vehicle)
