require ecs
require ecs.safe
require ecs.common
require app
require DagorSystem
require game.es.events
require game.es.player_events
require enlisted.game.es.spawn_soldier_events
require game.es.spawn_soldier_common
require game.es.vehicle.vehicle_events
require common_shooter.es.human.human_parachute_common

def get_item_sub_template(itemTemplate; slot) : string
  let tpl = getTemplateByName(itemTemplate)
  if tpl == null
    logerr("Cannot create an equipment: template '{itemTemplate}' is not found for the slot '{slot}'")
    return ""

  return getTemplateComponent(*tpl, "item__recreateInEquipment") ?? "base_vis_item"

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
    query(spawnerEid) <| $ [es] (equipmentEids : Object;
                                 useVechicle : EntityId;
                                 soldierIndexInSquad : int;
                                 squadEid : EntityId;
                                 playerEid : EntityId)
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

      if !!useVechicle
        use_vehicle_on_spawn(soldierEid, squadEid, playerEid, useVechicle, soldierIndexInSquad)

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
                                        shouldBePossessed : bool)
    if shouldBePossessed
      sendEvent(playerEid, [[CmdPossessEntity possessedEid=soldierEid]])
      ecs::query(squadEid) <| $ [es] (var squad__leader : EntityId&) { squad__leader = soldierEid; }

  destroyEntity(evt.spawnerEid)

// Do not send any net events from here, its used in finilizer block
def use_vehicle_on_spawn(possessed : EntityId; squad : EntityId; player_eid : EntityId; vehicle : EntityId; seat_order_no : int)
  query(vehicle) <| $ [es] (vehicle_seats__seatEids : EidList)
    if seat_order_no >= length(vehicle_seats__seatEids)
      logerr("Seats order index is out of range ({seat_order_no} >= {length(vehicle_seats__seatEids)})")
      return

    var isPlayer = false
    let seatNo = get_int(vehicle_seats__seatEids[seat_order_no], "seats_order__seatNo") ?? -1
    query(possessed) <| $ [es] (possessedByPlr : ecs::EntityId;
                                var isInVehicle : bool&;
                                var disable_collision : bool&;
                                var human_anim__vehicleSelected : ecs::EntityId&;
                                var human_vehicle__occupiedSeatEid : ecs::EntityId&;
                                var vehicle__lastEid : ecs::EntityId&;
                                var vehicle__lastTime : float&)
      if seatNo >= 0
        human_vehicle__occupiedSeatEid = vehicle_seats__seatEids[seatNo]

      isPlayer = possessedByPlr != INVALID_ENTITY_ID
      isInVehicle = true
      disable_collision = true
      human_anim__vehicleSelected = vehicle
      vehicle__lastEid = vehicle
      vehicle__lastTime = get_sync_time()

    if seatNo < 0
      return

    query(vehicle_seats__seatEids[seatNo]) <| $ [es] (seat__component : int;
                                                      var seat__isPlayer : bool&;
                                                      var seat__ownerEid : EntityId&;
                                                      var seat__playerEid : EntityId&;
                                                      var seat__squadEid : EntityId&)
      set(possessed, "", uint(seat__component), true)

      seat__isPlayer = isPlayer
      seat__ownerEid = possessed
      seat__playerEid = player_eid
      seat__squadEid = squad

[es(tag=server, REQUIRE=player)]
def cmd_use_vehicle_on_spawn_es(evt : CmdUseVehicleOnSpawn; eid : EntityId)
  use_vehicle_on_spawn(evt.possessed, evt.squad, eid, evt.vehicle, evt.seatOrderNo)
