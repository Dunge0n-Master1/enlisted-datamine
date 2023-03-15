require ecs
require ecs.safe
require ecs.common
require ecs.extra_set
require math.base
require AnimV20
require GeomNodeTree
require dm
require DmFire
require EnlistedDm
require fx
require DagorSystem
require game.es.vehicle.vehicle_events
require strings


enum VehicleEffectType
  FatalFire = 0
  EngineFire
  FatalExplosion
  Destroyed


def vehicle_fx_on_appear(vehicle_eid : EntityId;
                         effect_type : VehicleEffectType;
                         damage_model : DamageModel;
                         animchar : AnimcharBaseComponent;
                         fx_desc_array : Array;
                         var vehicle_fx_eids : EidList)
  for i, fxDescArrayItem in iter_range(fx_desc_array), fx_desc_array
    let fxDescItem = fxDescArrayItem as Object

    let vehicleFxEid = createEntity("vehicle_fx") <| $(var init)
      set(init, "vehicle_fx__ownerVehicleEid", vehicle_eid)
      set(init, "vehicle_fx__effectType", int(effect_type))
      set(init, "vehicle_fx__id", i)

      var dmPartIds : array<int>
      let dmParts = fxDescItem?.dmParts ?as Array
      if dmParts != null
        for dmPartItem in *dmParts
          let name = dmPartItem ?? ""
          let id = find_part_id_by_name(damage_model, name)
          if id >= 0
            push(dmPartIds, id)
          else
            logwarn("Part '{name}' not found!")
      set(init, "vehicle_fx__dmPartId", dmPartIds)

      var fxTemplateNames : array<string>
      var nodeIds : array<int>
      let fxArray = fxDescItem?.fx ?as Array
      if fxArray != null
        for fxItem in *fxArray
          let fx = fxItem as Object
          let fxTemplateName = fx?.name ?? ""
          let fxEmitterName = fx?.emitter ?? ""
          let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, fxEmitterName)
          if nodeId >= 0
            push(fxTemplateNames, fxTemplateName)
            push(nodeIds, nodeId)
          else
            logwarn("{vehicle_eid} <{getEntityTemplateName(vehicle_eid)}> FX emitter node '{fxEmitterName}' is not found!")

      set(init, "vehicle_fx_node__fxTemplateName", fxTemplateNames)
      set(init, "vehicle_fx_node__nodeId", nodeIds)

    push(vehicle_fx_eids, vehicleFxEid)


def vehicle_fx_on_disappear(vehicle_fx_eids : EidList)
  for vehicleFxEid in vehicle_fx_eids
    destroyEntity(vehicleFxEid)


[es(tag=render, on_appear)]
def fatal_fire_fx_on_appear(evt : Event;
                            eid : EntityId;
                            damage_model : DamageModel;
                            animchar : AnimcharBaseComponent;
                            fatal_fire_fx__fx : Array;
                            var fatal_fire_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType FatalFire, damage_model, animchar, fatal_fire_fx__fx, fatal_fire_fx__eids)

[es(tag=render, on_appear)]
def engine_fire_fx_on_appear(evt : Event;
                             eid : EntityId;
                             damage_model : DamageModel;
                             animchar : AnimcharBaseComponent;
                             engine_fire_fx__fx : Array;
                             var engine_fire_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType EngineFire, damage_model, animchar, engine_fire_fx__fx, engine_fire_fx__eids)

[es(tag=render, on_appear)]
def fatal_explosion_fx_on_appear(evt : Event;
                                 eid : EntityId;
                                 damage_model : DamageModel;
                                 animchar : AnimcharBaseComponent;
                                 fatal_explosion_fx__fx : Array;
                                 var fatal_explosion_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType FatalExplosion, damage_model, animchar, fatal_explosion_fx__fx, fatal_explosion_fx__eids)

[es(tag=render, on_appear)]
def destroyed_fx_on_appear(evt : Event;
                           eid : EntityId;
                           damage_model : DamageModel;
                           animchar : AnimcharBaseComponent;
                           destroyed_fx__fx : Array;
                           var destroyed_fx__eids : EidList)
  vehicle_fx_on_appear(eid, VehicleEffectType Destroyed, damage_model, animchar, destroyed_fx__fx, destroyed_fx__eids)

[es(tag=render, on_appear)]
def explosion_fx_on_appear(evt : Event;
                           animchar : AnimcharBaseComponent;
                           explosion_fx__nodeName : string;
                           var explosion_fx__nodeId : int&)
  explosion_fx__nodeId = geomtree_findNodeIndex(*animchar.nodeTree, explosion_fx__nodeName)

[es(tag=render, on_disappear)]
def fatal_fire_fx_on_disappear(evt : Event; fatal_fire_fx__eids : EidList)
  vehicle_fx_on_disappear(fatal_fire_fx__eids)

[es(tag=render, on_disappear)]
def engine_fire_fx_on_disappear(evt : Event; engine_fire_fx__eids : EidList)
  vehicle_fx_on_disappear(engine_fire_fx__eids)

[es(tag=render, on_disappear)]
def fatal_explosion_fx_on_disappear(evt : Event; fatal_explosion_fx__eids : EidList)
  vehicle_fx_on_disappear(fatal_explosion_fx__eids)

[es(tag=render, on_disappear)]
def destroyed_fx_on_disappear(evt : Event; destroyed_fx__eids : EidList)
  vehicle_fx_on_disappear(destroyed_fx__eids)


[es(tag=render, on_disappear)]
def vehicle_fx_destroy_effects_on_disappear(evt : Event;
                                            vehicle_fx__ownerVehicleEid : EntityId;
                                            vehicle_fx__effectType : int;
                                            vehicle_fx__id : int)
  query(vehicle_fx__ownerVehicleEid) <| $ [es] (vehicle_fxs__effectsEids : EidList)
    stop_fx(vehicle_fxs__effectsEids, vehicle_fx__effectType, vehicle_fx__id)


def stop_fx(vehicle_fxs__effectsEids : EidList; effect_type : int; vehicle_fx_id : int)
  for effectEid in vehicle_fxs__effectsEids
    query(effectEid) <| $ [es] (vehicle_effect__type : int; vehicle_effect__vehicleFxId : int)
      if vehicle_effect__type == effect_type && vehicle_effect__vehicleFxId == vehicle_fx_id
        destroyEntity(effectEid)


def stop_all_fxs(vehicle_fxs__effectsEids : EidList; effect_type : VehicleEffectType)
  for effectEid in vehicle_fxs__effectsEids
    query(effectEid) <| $ [es] (vehicle_effect__type : int)
      if vehicle_effect__type == int(effect_type)
        destroyEntity(effectEid)


def start_fx(vehicle_eid : EntityId;
             vehicle_fxs__effectsEids : EidList;
             transform : float3x4;
             animchar : AnimcharBaseComponent;
             vehicle_fx_eid : EntityId;
             vehicle_fx_id : int;
             effect_type : VehicleEffectType)
  let itm = inverse(transform)

  var isStateActive = false
  for effectEid in vehicle_fxs__effectsEids
    query(effectEid) <| $ [es] (vehicle_effect__type : int; vehicle_effect__vehicleFxId : int)
      isStateActive = vehicle_effect__type == int(effect_type) && vehicle_effect__vehicleFxId == vehicle_fx_id
    if isStateActive
      return

  stop_fx(vehicle_fxs__effectsEids, int(effect_type), vehicle_fx_id)

  query(vehicle_fx_eid) <| $ [es] (vehicle_fx_node__fxTemplateName : StringList;
                                   vehicle_fx_node__nodeId : IntList)
    for fxTemplateName, nodeId in vehicle_fx_node__fxTemplateName, vehicle_fx_node__nodeId
      if nodeId < 0
        continue

      var nodeTm : float3x4
      geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, nodeTm)

      var emitterTm = IDENT_TM
      emitterTm[3] = nodeTm[3]

      let eid = createEntity(string(fxTemplateName)) <| $(var init)
        set(init, "transform", emitterTm)
        set(init, "vehicle_effect__type", int(effect_type))
        set(init, "vehicle_effect__vehicleFxId", vehicle_fx_id)
        set(init, "vehicle_effect__emitterLocalPos", itm * emitterTm[3])
        set(init, "vehicle_effect__nodeId", nodeId)
        set(init, "vehicle_effect__vehicleEid", vehicle_eid)
        set(init, "vehicle_effect__emitterPos", emitterTm[3])


def start_all_fxs(vehicle_eid : EntityId;
                  vehicle_fxs__effectsEids : EidList;
                  transform : float3x4;
                  animchar : AnimcharBaseComponent;
                  vehicle_fx_eids : EidList;
                  effect_type : VehicleEffectType)
  for i, vehicleFxEid in iter_range(vehicle_fx_eids), vehicle_fx_eids
    start_fx(vehicle_eid, vehicle_fxs__effectsEids, transform, animchar, vehicleFxEid, i, effect_type)


def is_effect_should_be_active(vehicle_fx_eid : EntityId;
                               fire_damage_state : FireDamageState)
  var result = false
  query(vehicle_fx_eid) <| $ [es] (vehicle_fx__dmPartId : IntList)
    for state in fire_damage_state.states
      if state.startTime <= 0.0
        continue
      if find_index(vehicle_fx__dmPartId, int(state.partId.id)) > -1
        result = true
        break
  return result


[es(tag=render, REQUIRE=damage_model, track=fire_damage_state)]
def fire_fx_check_state_es_event_handler(evt : Event;
                                         eid : EntityId;
                                         transform : float3x4;
                                         vehicle__isUnderwater : bool;
                                         fire_damage_state : FireDamageState;
                                         animchar : AnimcharBaseComponent;
                                         engine_fire_fx__eids : EidList;
                                         vehicle_fxs__effectsEids : EidList)
  for i, vehicleFxEid in iter_range(engine_fire_fx__eids), engine_fire_fx__eids
    if is_effect_should_be_active(vehicleFxEid, fire_damage_state) && !vehicle__isUnderwater
      start_fx(eid, vehicle_fxs__effectsEids, transform, animchar, vehicleFxEid, i, VehicleEffectType EngineFire)
    else
      stop_fx(vehicle_fxs__effectsEids, int(VehicleEffectType EngineFire), i)


[es(tag=render, REQUIRE=damage_model)]
def explosion_fx_es(evt : EventExplosionFatal;
                    eid : EntityId;
                    transform : float3x4;
                    vehicle__isUnderwater : bool;
                    animchar : AnimcharBaseComponent;
                    fatal_explosion_fx__eids : EidList;
                    vehicle_fxs__effectsEids : EidList)
  stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalFire)
  if !vehicle__isUnderwater
    start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, fatal_explosion_fx__eids, VehicleEffectType FatalExplosion)


[es(tag=render, REQUIRE=damage_model)]
def fatal_fire_fx_es(evt : EventFireFatal;
                     eid : EntityId;
                     transform : float3x4;
                     vehicle__isUnderwater : bool;
                     animchar : AnimcharBaseComponent;
                     fatal_fire_fx__eids : EidList;
                     vehicle_fxs__effectsEids : EidList;
                     isExploded : bool)
  if !isExploded && !vehicle__isUnderwater
    start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, fatal_fire_fx__eids, VehicleEffectType FatalFire)


[es(tag=render, REQUIRE=fatal_fire_fx__eids)]
def dm_restore_fx_es(evt : CmdRestore; vehicle_fxs__effectsEids : EidList)
  stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalFire)
  stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalExplosion)


[es(tag=render, track=isExploded)]
def fatal_explosion_fx_check_es(evt : Event;
                                eid : EntityId;
                                transform : float3x4;
                                vehicle__isUnderwater : bool;
                                animchar : AnimcharBaseComponent;
                                fatal_explosion_fx__eids : EidList;
                                vehicle_fxs__effectsEids : EidList;
                                isExploded : bool;
                                var isFatalExplosionFxStarted : bool&)
  if isExploded && !isFatalExplosionFxStarted
    isFatalExplosionFxStarted = true
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalFire)
    if !vehicle__isUnderwater
      start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, fatal_explosion_fx__eids, VehicleEffectType FatalExplosion)


[es(tag=render)]
def destroyed_fx_start_es(info : UpdateStageInfoAct;
                          eid : EntityId;
                          transform : float3x4;
                          vehicle__isUnderwater : bool;
                          animchar : AnimcharBaseComponent;
                          destroyed_fx__eids : EidList;
                          vehicle_fxs__effectsEids : EidList;
                          fatal_explosion_fire__endTime : float;
                          isExploded : bool;
                          var isFatalExplosionFxStarted : bool&;
                          var isDestroyedFxStarted : bool&)
  if isFatalExplosionFxStarted && info.curTime >= fatal_explosion_fire__endTime
    if fatal_explosion_fire__endTime > 0.f
      isFatalExplosionFxStarted = false
      stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalExplosion)

    if !isDestroyedFxStarted && isExploded
      isDestroyedFxStarted = true
      if !vehicle__isUnderwater
        start_all_fxs(eid, vehicle_fxs__effectsEids, transform, animchar, destroyed_fx__eids, VehicleEffectType Destroyed)


[es(tag=render, track=vehicle__isUnderwater)]
def vehicle_fx_stop_all_on_flooding(evt : Event;
                                    vehicle_fxs__effectsEids : EidList;
                                    vehicle__isUnderwater : bool)
  if vehicle__isUnderwater
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalFire)
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType EngineFire)
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType FatalExplosion)
    stop_all_fxs(vehicle_fxs__effectsEids, VehicleEffectType Destroyed)


[es(tag=render, track=isExploded, REQUIRE=damage_model)]
def damage_model_fx_es(evt : Event;
                       eid : EntityId;
                       transform : float3x4;
                       vehicle__isUnderwater : bool;
                       animchar : AnimcharBaseComponent;
                       explosion_fx__effectName : string;
                       explosion_fx__nodeId : int;
                       isExploded : bool)
  if !isExploded || vehicle__isUnderwater || empty(explosion_fx__effectName)
    return

  var fxTm = IDENT_TM
  fxTm[3] = (explosion_fx__nodeId >= 0
          ? geomtree_getNodeWpos(*animchar.nodeTree, explosion_fx__nodeId)
          : transform[3])
  createEntity(explosion_fx__effectName) <| $(var init)
    set(init, "transform", fxTm)
    set(init, "vehicle_effect__vehicleEid", eid)


[es(tag=render, on_appear, REQUIRE=vehicleEffect)]
def vehicle_effect_on_appear(evt : Event; eid : EntityId; vehicle_effect__vehicleEid : EntityId)
  query(vehicle_effect__vehicleEid) <| $ [es] (var vehicle_fxs__effectsEids : EidList)
    push(vehicle_fxs__effectsEids, eid)


[es(tag=render, on_disappear, REQUIRE=vehicleEffect)]
def vehicle_effect_on_disappear(evt : Event; eid : EntityId; vehicle_effect__vehicleEid : EntityId)
  query(vehicle_effect__vehicleEid) <| $ [es] (var vehicle_fxs__effectsEids : EidList)
    let effectIdx = find_index(vehicle_fxs__effectsEids, eid)
    if effectIdx > -1
      erase(vehicle_fxs__effectsEids, effectIdx)


[es(tag=render, on_disappear)]
def vehicle_effect_destroy_on_vehicle_disappear(evt : Event;
                                                var vehicle_fxs__effectsEids : EidList&)
  for vehicleEffectEid in vehicle_fxs__effectsEids
    destroyEntity(vehicleEffectEid)
  vehicle_fxs__effectsEids |> clear()


[es(tag=render, no_order)]
def vehicle_effect_update_emitter_pos(info : UpdateStageInfoAct;
                                      vehicle_effect__emitterLocalPos : float3;
                                      vehicle_effect__vehicleEid : EntityId;
                                      vehicle_effect__minDistSqToUpdateEmitterTm : float;
                                      var vehicle_effect__emitterPos : float3&)
  query(vehicle_effect__vehicleEid) <| $ [es] (transform : float3x4; animchar__updatable : bool)
    if animchar__updatable
      let emitterPos = transform * vehicle_effect__emitterLocalPos
      if length_sq(emitterPos - vehicle_effect__emitterPos) > vehicle_effect__minDistSqToUpdateEmitterTm
        vehicle_effect__emitterPos = emitterPos


[es(tag=render, on_appear, track=vehicle_effect__emitterPos)]
def vehicle_effect_update_emitter_tm(evt : Event; vehicle_effect__emitterPos : float3; var effect : TheEffect)
  var emitterTm = IDENT_TM
  emitterTm[3] = vehicle_effect__emitterPos
  effect_set_emitter_tm(effect, emitterTm)
