require ecs
require ecs.safe
require ecs.common
require enlisted.events_enlisted
require CollRes
require AnimV20
require dm


enum TankState
  Normal = 0
  Leak
  Burn


def create_damage_fx(collres : CollisionResource;
                     dm_part_id : int;
                     transform : float3x4;
                     animchar : AnimcharBaseComponent;
                     effect_template : string;
                     eid : EntityId)
  var emitterTm : float3x4
  collres_get_collision_node_tm(collres, dm_part_id, transform, animchar.nodeTree, emitterTm)

  return createEntity(effect_template) <| $(var init)
    set(init, "transform", emitterTm)
    set(init, "plane_effect__nodeId", dm_part_id)
    set(init, "plane_effect__planeEid", eid)
    set(init, "plane_effect__emitterPos", emitterTm[3])
    set(init, "plane_effect__emitterLocalPos", inverse(transform) * emitterTm[3])


def init_dm_parts_ids_by_names(damage_model : DamageModel; names : StringList; var ids : IntList)
  for nodeName in names
    let nodeId = find_part_id_by_name(damage_model, string(nodeName))
    if nodeId > -1
      push(ids, nodeId)


[es(tag=render, on_appear)]
def plane_tank_damage_fx_on_appear(evt : Event;
                                   damage_model : DamageModel;
                                   plane_tank_damage_fx__waterEmitters : StringList;
                                   plane_tank_damage_fx__fuelEmitters : StringList;
                                   plane_tank_damage_fx__oilEmitters : StringList;
                                   var plane_tank_damage_fx__waterEmittersIds : IntList;
                                   var plane_tank_damage_fx__fuelEmittersIds : IntList;
                                   var plane_tank_damage_fx__oilEmittersIds : IntList;
                                   var plane_tank_damage_fx__waterFxEids : EidList;
                                   var plane_tank_damage_fx__fuelFxEids : EidList;
                                   var plane_tank_damage_fx__oilFxEids : EidList;
                                   var plane_tank_damage_fx__fuelState : IntList)
  init_dm_parts_ids_by_names(damage_model, plane_tank_damage_fx__waterEmitters, plane_tank_damage_fx__waterEmittersIds)
  init_dm_parts_ids_by_names(damage_model, plane_tank_damage_fx__fuelEmitters, plane_tank_damage_fx__fuelEmittersIds)
  init_dm_parts_ids_by_names(damage_model, plane_tank_damage_fx__oilEmitters, plane_tank_damage_fx__oilEmittersIds)

  resize(plane_tank_damage_fx__waterFxEids, length(plane_tank_damage_fx__waterEmittersIds))
  resize(plane_tank_damage_fx__fuelFxEids, length(plane_tank_damage_fx__fuelEmittersIds))
  resize(plane_tank_damage_fx__oilFxEids, length(plane_tank_damage_fx__oilEmittersIds))

  resize(plane_tank_damage_fx__fuelState, length(plane_tank_damage_fx__fuelEmittersIds))


[es(tag=render, on_disappear)]
def plane_tank_damage_fx_on_disappear(evt : Event;
                                      var plane_tank_damage_fx__waterFxEids : EidList;
                                      var plane_tank_damage_fx__fuelFxEids : EidList;
                                      var plane_tank_damage_fx__oilFxEids : EidList)
  for fxEid in plane_tank_damage_fx__waterFxEids
    destroyEntity(fxEid)
  for fxEid in plane_tank_damage_fx__fuelFxEids
    destroyEntity(fxEid)
  for fxEid in plane_tank_damage_fx__oilFxEids
    destroyEntity(fxEid)


[es(tag=render, track=(waterLeakages, aircraft_state_engine__hasWater, plane_engine_damage_fx__isAnyEngineDamaged))]
def plane_water_tank_damage_fx_on_update(evt : Event;
                                         eid : EntityId;
                                         transform : float3x4;
                                         collres : CollisionResource;
                                         animchar : AnimcharBaseComponent;
                                         waterLeakages : BoolList;
                                         waterToEngineMap : IntList;
                                         aircraft_state_engine__hasWater : BoolList;
                                         plane_engine_damage_fx__isAnyEngineDamaged : bool;
                                         plane_tank_damage_fx__waterLeakEffect : string;
                                         plane_tank_damage_fx__waterEmittersIds : IntList;
                                         var plane_tank_damage_fx__waterFxEids : EidList)
  for isLeak, engineIndex, emitterPartId, fxEid in waterLeakages, waterToEngineMap, plane_tank_damage_fx__waterEmittersIds, plane_tank_damage_fx__waterFxEids
    let hasWater = aircraft_state_engine__hasWater?[engineIndex] ?? false
    let isFxEnabled = isLeak && hasWater && !plane_engine_damage_fx__isAnyEngineDamaged

    if isFxEnabled && !fxEid
      fxEid = create_damage_fx(collres, emitterPartId, transform, animchar, plane_tank_damage_fx__waterLeakEffect, eid)
    elif !isFxEnabled && !!fxEid
      destroyEntity(fxEid)
      fxEid = INVALID_ENTITY_ID


[es(tag=render, track=(fuelTanksFire, aircraft_state__isFuelTankLeaks, plane_engine_damage_fx__isAnyEngineBurning))]
def plane_fuel_tank_damage_fx_on_update(evt : Event;
                                        eid : EntityId;
                                        transform : float3x4;
                                        collres : CollisionResource;
                                        animchar : AnimcharBaseComponent;
                                        fuelTanksFire : BoolList;
                                        aircraft_state__isFuelTankLeaks : BoolList;
                                        plane_engine_damage_fx__isAnyEngineBurning : bool;
                                        plane_tank_damage_fx__fuelLeakEffect : string;
                                        plane_tank_damage_fx__additionalFireEffect : string;
                                        plane_tank_damage_fx__fuelEmittersIds : IntList;
                                        var plane_tank_damage_fx__fuelFxEids : EidList;
                                        var plane_tank_damage_fx__fuelState : IntList)
  assume isFuelTankLeaks = aircraft_state__isFuelTankLeaks
  assume fuelStates = plane_tank_damage_fx__fuelState
  assume fuelEmittersIds = plane_tank_damage_fx__fuelEmittersIds
  assume fuelFxEids = plane_tank_damage_fx__fuelFxEids

  for isBurning, isLeak, tankState, emitterPartId, fxEid in fuelTanksFire, isFuelTankLeaks, fuelStates, fuelEmittersIds, fuelFxEids
    var newTankState = TankState Normal
    if isLeak
      newTankState = TankState Leak

    if newTankState == TankState Leak && (isBurning || plane_engine_damage_fx__isAnyEngineBurning)
      newTankState = TankState Burn

    if tankState != int(newTankState)
      destroyEntity(fxEid)
      fxEid = INVALID_ENTITY_ID

      if newTankState == TankState Leak
        fxEid = create_damage_fx(collres, emitterPartId, transform, animchar, plane_tank_damage_fx__fuelLeakEffect, eid)
      elif newTankState == TankState Burn
        fxEid = create_damage_fx(collres, emitterPartId, transform, animchar, plane_tank_damage_fx__additionalFireEffect, eid)

    tankState = int(newTankState)


[es(tag=render, track=(oilLeakages, aircraft_state_engine__hasOil, plane_engine_damage_fx__isAnyEngineDamaged))]
def plane_oil_tank_damage_fx_on_update(evt : Event;
                                       eid : EntityId;
                                       transform : float3x4;
                                       collres : CollisionResource;
                                       animchar : AnimcharBaseComponent;
                                       oilLeakages : BoolList;
                                       oilToEngineMap : IntList;
                                       aircraft_state_engine__hasOil : BoolList;
                                       plane_engine_damage_fx__isAnyEngineDamaged : bool;
                                       plane_tank_damage_fx__oilLeakEffect : string;
                                       plane_tank_damage_fx__oilEmittersIds : IntList;
                                       var plane_tank_damage_fx__oilFxEids : EidList)
  for isLeak, engineIndex, emitterPartId, fxEid in oilLeakages, oilToEngineMap, plane_tank_damage_fx__oilEmittersIds, plane_tank_damage_fx__oilFxEids
    let hasOil = aircraft_state_engine__hasOil?[engineIndex] ?? false
    let isFxEnabled = isLeak && hasOil && !plane_engine_damage_fx__isAnyEngineDamaged

    if isFxEnabled && !fxEid
      fxEid = create_damage_fx(collres, emitterPartId, transform, animchar, plane_tank_damage_fx__oilLeakEffect, eid)
    elif !isFxEnabled && !!fxEid
      destroyEntity(fxEid)
      fxEid = INVALID_ENTITY_ID
