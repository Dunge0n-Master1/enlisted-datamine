require ecs
require ecs.common
require DagorSystem
require game.es.events
require game.es.player_events
require enlisted.game.es.spawn_soldier_events
require game.es.spawn_soldier_common
require game.es.vehicle.vehicle_events

def get_item_sub_template(itemTemplate; slot) : string
  let tpl = getTemplateByName(itemTemplate)
  if tpl == null
    logerr("Cannot create an equipment: template '{itemTemplate}' is not found for the slot '{slot}'")
    return ""

  return get_string(getTemplateComponent(*tpl, "item__recreateInEquipment"), "base_vis_item")

[es(tag=server, on_appear)]
def spawn_soldier(evt : Event; eid : EntityId; var soldierComponents : Object; var equipmentLeftToCreate : int&)
  var equipmentPtr = getRW_ecs_object(soldierComponents, "human_equipment__initialEquip")
  assume equipment = *equipmentPtr
  var equipmentComponentsPtr = getRW_ecs_object(soldierComponents, "human_equipment__initialEquipComponents")
  assume equipmentComponents = *equipmentComponentsPtr

  equipmentLeftToCreate = length(equipment)

  let spawnerEid = eid
  for kv in equipment
    let gametempate = kv.key
    let slot := get_string(kv.value, "")
    let addTemplate = get_item_sub_template(gametempate, slot)

    let finalizeCreation <- @ <| (itemEid : EntityId)
      ecs::query(spawnerEid) <| $ [es] (var equipmentEids : Object; var equipmentLeftToCreate : int&)
        set(equipmentEids, slot, itemEid)
        equipmentLeftToCreate -= 1
        if equipmentLeftToCreate <= 0
          sendEvent(spawnerEid, [[SoldierSpawnEquipmentCreated]])

    createEntity("{gametempate}+{addTemplate}", finalizeCreation) <| $(var init : ComponentsInitializer)
      let components = get_ecs_object(equipmentComponents, gametempate)
      if components != null
        let tpl = getTemplateByName(gametempate)
        for comp in *components
          let keyHash = ecs_hash(comp.key)
          if tpl != null && templateHasComponent(*tpl, comp.key, keyHash)
            set(init, comp.key, keyHash, comp.value)

  clear(equipment)
  clear(equipmentComponents)

def init_item_container(eid)
  ecs::query(eid) <| $ [es] (itemContainer : EidList)
    for itemEid in itemContainer
      query(itemEid) <| $ [es] (var item__lastOwner : EntityId&; var item__ownerEid : EntityId&)
        item__lastOwner = eid
        item__ownerEid = eid

[es(tag=server, on_event=SoldierSpawnEquipmentCreated, REQUIRE=soldierComponents)]
def spawn_soldier_done(evt : Event;
                       eid : EntityId;
                       soldierTemplate : string;
                       soldierComponents : Object const?) // a pointer but required, we need a pointer to call init_soldier_tpl_deps
  let spawnerEid = eid
  let finalizeCreation <- @ <| (soldierEid : EntityId)
    // The soldier is initialized as soon as possible so as many parameters are synchronized in the initial replication packet
    ecs::query(spawnerEid) <| $ [es] (equipmentEids : Object)
      for item in equipmentEids
        let itemEid = *get_Eid(item.value)
        sendEventImmediate(soldierEid, [[CmdEquipItemDirect itemEid=itemEid, slot=item.key, allowReorderSlots=false, dropPrevItem=true]])
        ecs::query(itemEid) <| $ [es] (var skeleton_attach__attached : bool&;
                                       var slot_attach__attachedTo : EntityId&;
                                       var skeleton_attach__attachedTo : EntityId&)
          slot_attach__attachedTo = soldierEid
          skeleton_attach__attached = true
          skeleton_attach__attachedTo  = soldierEid
        ecs::query(itemEid) <| $ [es] (footprintType : int)
          let itemFootprintType = footprintType
          ecs::query(soldierEid) <| $ [es] (var footprintType : int&)
            footprintType = itemFootprintType
      init_item_container(soldierEid)

  let baseTemplateName = split_template(soldierTemplate)[0]
  let tpl = getTemplateByName(baseTemplateName)
  let soldierEid : EntityId = createEntity(soldierTemplate, finalizeCreation) <| $(var init : ComponentsInitializer)
    if tpl == null || !init_soldier_tpl_deps(*tpl, /*out*/ init, soldierComponents)
      logerr("Can't create a list of entities for instantiation for '{soldierTemplate}'")

    for comp in *soldierComponents
      let keyHash = ecs_hash(comp.key)
      if tpl != null && templateHasComponent(*tpl, comp.key, keyHash)
        set(init, comp.key, keyHash, comp.value)
  sendEvent(soldierEid, [[FinalizeSoldierCreation spawnerEid=eid]])

[es(tag=server)]
def finalize_soldier_creation(evt : FinalizeSoldierCreation; eid : EntityId)
  let soldierEid : EntityId = eid
  ecs::query(evt.spawnerEid) <| $ [es] (playerEid : EntityId;
                                        squadEid : EntityId;
                                        useVechicle : EntityId;
                                        soldierIndexInSquad : int;
                                        shouldBePossessed : bool)
    if shouldBePossessed
      sendEvent(playerEid, [[CmdPossessEntity possessedEid=soldierEid]])
      ecs::query(squadEid) <| $ [es] (var squad__leader : EntityId&) { squad__leader = soldierEid; }

    if useVechicle != INVALID_ENTITY_ID
      sendEvent(playerEid, [[CmdUseVehicleOnSpawn possessed=soldierEid, squad=squadEid, vehicle=useVechicle, seatOrderNo=soldierIndexInSquad]])

  destroyEntity(evt.spawnerEid)
