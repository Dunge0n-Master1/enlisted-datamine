require ecs
require ecs.safe
require ecs.common
require app
require DagorSystem
require AnimV20
require CollRes
require game.es.events
require game.es.player_events
require enlisted.game.es.spawn_soldier_events
require game.es.spawn_soldier_common
require game.es.vehicle.vehicle_seats_common
require game.es.vehicle.vehicle_events
require common_shooter.es.human.human_parachute_common
require game.es.artillery_aircraft_common

[es(tag=server, on_appear)]
def spawn_soldier(evt : Event;
                  eid : EntityId;
                  useVechicle : EntityId = INVALID_ENTITY_ID;
                  var soldierComponents : Object;
                  var equipmentLeftToCreate : int&)
  var equipmentPtr = getRW_ecs_object(soldierComponents, "human_equipment__initialEquip")
  assume equipment = *equipmentPtr
  var equipmentComponentsPtr = getRW_ecs_object(soldierComponents, "human_equipment__initialEquipComponents")
  assume equipmentComponents = *equipmentComponentsPtr

  equipmentLeftToCreate = length(equipment)

  let spawnerEid = eid
  for kv in equipment
    let gametempate = kv.key
    let slot := get_string(kv.value, "")

    let itemTemplate = get_item_template_for_equipment(gametempate, !!useVechicle)
    if empty(itemTemplate)
      equipmentLeftToCreate -= 1
      continue

    let finalizeCreation <- @ <| (itemEid : EntityId)
      ecs::query(spawnerEid) <| $ [es] (var equipmentEids : Object; var equipmentLeftToCreate : int&)
        set(equipmentEids, slot, itemEid)
        equipmentLeftToCreate -= 1
        if equipmentLeftToCreate <= 0
          sendEvent(spawnerEid, [[SoldierSpawnEquipmentCreated]])

    createEntity(itemTemplate, finalizeCreation) <| $(var init : ComponentsInitializer)
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
  query(vehicle) <| $ [es] (vehicle_seats__seatEids : EidList;
                            animchar : AnimcharBaseComponent;
                            collres : CollisionResource;
                            transform aka vehicle_transform : float3x4)
    if seat_order_no >= length(vehicle_seats__seatEids)
      logerr("Seats order index is out of range ({seat_order_no} >= {length(vehicle_seats__seatEids)})")
      return

    var isPlayer = false
    let seatNo = get_int(vehicle_seats__seatEids[seat_order_no], "seats_order__seatNo") ?? -1
    query(possessed) <| $ [es] (possessedByPlr : ecs::EntityId;
                                var transform aka human_transform : float3x4&;
                                var isInVehicle : bool&;
                                var disable_collision : bool&;
                                var human_anim__vehicleSelected : ecs::EntityId&;
                                var human_vehicle__occupiedSeatEid : ecs::EntityId&;
                                var vehicle__lastEid : ecs::EntityId&;
                                var vehicle__lastTime : float&;
                                var vehicle__localSeatTm : float3x4&;
                                var vehicle__globalSeatTm : float3x4&)
      if seatNo >= 0
        human_vehicle__occupiedSeatEid = vehicle_seats__seatEids[seatNo]
        if get_seat_attach_tm(human_vehicle__occupiedSeatEid, animchar, collres, vehicle_transform, vehicle__globalSeatTm)
          let inverseTm = inverse(vehicle_transform);
          vehicle__localSeatTm = inverseTm * vehicle__globalSeatTm
          human_transform = vehicle__globalSeatTm

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
