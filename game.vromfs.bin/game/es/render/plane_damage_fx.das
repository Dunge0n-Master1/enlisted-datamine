require ecs
require ecs.safe
require ecs.common
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require CollRes
require AnimV20
require DmFire
require fx
require dm
require EnlistedPlane
require Plane
require math.base


enum DamageFxType
  Water = 0
  Fuel
  Oil
  EngineBurning
  EngineDamaged
  EngineDestroyed
  Crash


def create_damage_fx(damage_fx_type : int;
                     collres : CollisionResource;
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
    set(init, "plane_effect__fxType", damage_fx_type)
    set(init, "plane_effect__planeEid", eid)
    set(init, "plane_effect__emitterPos", emitterTm[3])
    set(init, "plane_effect__emitterLocalPos", inverse(transform) * emitterTm[3])


def is_dm_part_burning(fire_damage_state : FireDamageState; part_id : int)
  for state in fire_damage_state.states
    if state.startTime > 0.0 && int(state.partId.id) == part_id
      return true
  return false


def init_dm_parts_ids_by_names(damage_model : DamageModel; names : StringList; var ids : IntList)
  for nodeName in names
    let nodeId = find_part_id_by_name(damage_model, string(nodeName))
    if nodeId > -1
      push(ids, nodeId)


[es(tag=render, on_appear)]
def plane_damage_fx_on_appear(evt : Event;
                              damage_model : DamageModel;
                              plane_damage_fx__enginesEmitters : StringList;
                              plane_damage_fx__fuelTankEmitters : StringList;
                              plane_damage_fx__oilEmitters : StringList;
                              plane_damage_fx__waterEmitters : StringList;
                              plane_damage_fx__tailSmokeEmitters : StringList;
                              var plane_damage_fx__enginesEmittersIds : IntList;
                              var plane_damage_fx__fuelTankEmittersIds : IntList;
                              var plane_damage_fx__oilEmittersIds : IntList;
                              var plane_damage_fx__waterEmittersIds : IntList;
                              var plane_damage_fx__tailSmokeEmittersIds : IntList)
  init_dm_parts_ids_by_names(damage_model, plane_damage_fx__enginesEmitters, plane_damage_fx__enginesEmittersIds)
  init_dm_parts_ids_by_names(damage_model, plane_damage_fx__fuelTankEmitters, plane_damage_fx__fuelTankEmittersIds)
  init_dm_parts_ids_by_names(damage_model, plane_damage_fx__oilEmitters, plane_damage_fx__oilEmittersIds)
  init_dm_parts_ids_by_names(damage_model, plane_damage_fx__waterEmitters, plane_damage_fx__waterEmittersIds)
  init_dm_parts_ids_by_names(damage_model, plane_damage_fx__tailSmokeEmitters, plane_damage_fx__tailSmokeEmittersIds)


[es(tag=render, on_disappear)]
def plane_damage_fx_on_disappear(evt : Event;
                                 plane_damage_fx__damageFxEid : EntityId;
                                 plane_damage_fx__additionalFireFxEid : EntityId)
  destroyEntity(plane_damage_fx__damageFxEid)
  destroyEntity(plane_damage_fx__additionalFireFxEid)


[es(tag=render)]
def plane_damage_fx_on_crash(evt : EventCrashExplosionFatal;
                             transform : float3x4;
                             plane_damage_fx__landCrashEffect : string;
                             plane_damage_fx__waterCrashEffect : string;
                             var plane_damage_fx__damageFxEid : EntityId&)
  let newFxType = int(DamageFxType Crash)
  let oldFxType = get_int(plane_damage_fx__damageFxEid, "plane_effect__fxType") ?? -1
  if oldFxType > newFxType
    return

  let isOnWater = evt.crashType == int(CrashType CRASH_TYPE_WATER)
  let effectTemplate = isOnWater ? plane_damage_fx__waterCrashEffect : plane_damage_fx__landCrashEffect

  destroyEntity(plane_damage_fx__damageFxEid)

  plane_damage_fx__damageFxEid = createEntity(effectTemplate) <| $(var init)
    var fxTm = IDENT_TM
    fxTm[3] = transform[3]
    set(init, "transform", fxTm)


[es(tag=render)]
def plane_damage_fx_on_tank_damaged(evt : EventOnPartDamaged;
                                    eid : EntityId;
                                    transform : float3x4;
                                    collres : CollisionResource;
                                    animchar : AnimcharBaseComponent;
                                    plane_damage_fx__waterLeakEffect : string;
                                    plane_damage_fx__fuelLeakEffect : string;
                                    plane_damage_fx__oilLeakEffect : string;
                                    plane_damage_fx__fuelTankEmittersIds : IntList;
                                    plane_damage_fx__oilEmittersIds : IntList;
                                    plane_damage_fx__waterEmittersIds : IntList;
                                    plane_damage_fx__additionalFireFxEid : EntityId;
                                    var plane_damage_fx__damageFxEid : EntityId&)
  let additionalFireFxPartId = get_int(plane_damage_fx__additionalFireFxEid, "plane_effect__nodeId") ?? -1
  if evt.partId == additionalFireFxPartId
    return

  var newFxType = -1
  var effectTemplate = ""

  if find_index(plane_damage_fx__waterEmittersIds, evt.partId) > -1
    newFxType = int(DamageFxType Water)
    effectTemplate = plane_damage_fx__waterLeakEffect
  elif find_index(plane_damage_fx__fuelTankEmittersIds, evt.partId) > -1
    newFxType = int(DamageFxType Fuel)
    effectTemplate = plane_damage_fx__fuelLeakEffect
  elif find_index(plane_damage_fx__oilEmittersIds, evt.partId) > -1
    newFxType = int(DamageFxType Oil)
    effectTemplate = plane_damage_fx__oilLeakEffect

  let oldFxType = get_int(plane_damage_fx__damageFxEid, "plane_effect__fxType") ?? -1
  if newFxType < 0 || oldFxType > newFxType
    return

  destroyEntity(plane_damage_fx__damageFxEid)
  plane_damage_fx__damageFxEid = create_damage_fx(newFxType, collres, evt.partId, transform, animchar, effectTemplate, eid)


[es(tag=render, track=(aircraft_state_engine__hasFuel, aircraft_state_engine__hasOil, aircraft_state_engine__hasWater))]
def plane_damage_fx_stop_tank_leakage(evt : Event;
                                      aircraft_state_engine__hasFuel : BoolList;
                                      aircraft_state_engine__hasOil : BoolList;
                                      aircraft_state_engine__hasWater : BoolList;
                                      plane_damage_fx__damageFxEid : EntityId)
  let damageFxType = get_int(plane_damage_fx__damageFxEid, "plane_effect__fxType") ?? -1

  let needDestroyFx = (damageFxType == int(DamageFxType Fuel) ? find_index(aircraft_state_engine__hasFuel, true) < 0
                    : damageFxType == int(DamageFxType Oil) ? find_index(aircraft_state_engine__hasOil, true) < 0
                    : damageFxType == int(DamageFxType Water) ? find_index(aircraft_state_engine__hasWater, true) < 0
                    : false)

  if needDestroyFx
    destroyEntity(plane_damage_fx__damageFxEid)


def update_engine_damage_fx(dm_part_id : int;
                            eid : EntityId;
                            transform : float3x4;
                            collres : CollisionResource;
                            animchar : AnimcharBaseComponent;
                            aircraft_state_engine__damageStage : UInt8List;
                            fire_damage_state : FireDamageState;
                            plane_damage_fx__engineBurningEffect : string;
                            plane_damage_fx__engineDamagedEffect : string;
                            plane_damage_fx__engineDestroyedEffect : string;
                            plane_damage_fx__enginesEmittersIds : IntList;
                            plane_damage_fx__additionalFireFxEid : EntityId;
                            var plane_damage_fx__damageFxEid : EntityId&;
                            var plane_damage_fx__lastDamagedEnginePartId : int&)
  let engineIndex = find_index(plane_damage_fx__enginesEmittersIds, dm_part_id)
  if engineIndex < 0 || engineIndex >= length(aircraft_state_engine__damageStage)
    return

  plane_damage_fx__lastDamagedEnginePartId = dm_part_id

  let isPartBurning = is_dm_part_burning(fire_damage_state, dm_part_id)
  let engineDamageStage = int(aircraft_state_engine__damageStage[engineIndex])

  let isEngineBurning = isPartBurning && engineDamageStage == 0
  let isEngineDamaged = !isEngineBurning && engineDamageStage == 1
  let isEngineDestroyed = !isEngineBurning && engineDamageStage == 2

  var newFxType = -1
  var effectTemplate = ""

  if isEngineBurning
    newFxType = int(DamageFxType EngineBurning)
    effectTemplate = plane_damage_fx__engineBurningEffect
  elif isEngineDamaged
    newFxType = int(DamageFxType EngineDamaged)
    effectTemplate = plane_damage_fx__engineDamagedEffect
  elif isEngineDestroyed
    newFxType = int(DamageFxType EngineDestroyed)
    effectTemplate = plane_damage_fx__engineDestroyedEffect

  let oldFxType = get_int(plane_damage_fx__damageFxEid, "plane_effect__fxType") ?? -1
  if newFxType < 0 || oldFxType >= newFxType
    return

  destroyEntity(plane_damage_fx__damageFxEid)
  query(plane_damage_fx__additionalFireFxEid) <| $ [es] (plane_effect__nodeId : int)
    if plane_effect__nodeId == dm_part_id
      destroyEntity(plane_damage_fx__additionalFireFxEid)

  plane_damage_fx__damageFxEid = create_damage_fx(newFxType, collres, dm_part_id, transform, animchar, effectTemplate, eid)


[es(tag=render)]
def plane_damage_fx_on_engine_damaged(evt : EventOnPartDamaged;
                                      eid : EntityId;
                                      transform : float3x4;
                                      collres : CollisionResource;
                                      animchar : AnimcharBaseComponent;
                                      aircraft_state_engine__damageStage : UInt8List;
                                      fire_damage_state : FireDamageState;
                                      plane_damage_fx__engineBurningEffect : string;
                                      plane_damage_fx__engineDamagedEffect : string;
                                      plane_damage_fx__engineDestroyedEffect : string;
                                      plane_damage_fx__enginesEmittersIds : IntList;
                                      plane_damage_fx__additionalFireFxEid : EntityId;
                                      var plane_damage_fx__damageFxEid : EntityId&;
                                      var plane_damage_fx__lastDamagedEnginePartId : int&)
  update_engine_damage_fx(evt.partId,
                          eid,
                          transform,
                          collres,
                          animchar,
                          aircraft_state_engine__damageStage,
                          fire_damage_state,
                          plane_damage_fx__engineBurningEffect,
                          plane_damage_fx__engineDamagedEffect,
                          plane_damage_fx__engineDestroyedEffect,
                          plane_damage_fx__enginesEmittersIds,
                          plane_damage_fx__additionalFireFxEid,
                          plane_damage_fx__damageFxEid,
                          plane_damage_fx__lastDamagedEnginePartId)



[es(tag=render, track=aircraft_state_engine__damageStage)]
def plane_damage_fx_update_engine_fx_stage(evt : Event;
                                           eid : EntityId;
                                           transform : float3x4;
                                           collres : CollisionResource;
                                           animchar : AnimcharBaseComponent;
                                           aircraft_state_engine__damageStage : UInt8List;
                                           fire_damage_state : FireDamageState;
                                           plane_damage_fx__engineBurningEffect : string;
                                           plane_damage_fx__engineDamagedEffect : string;
                                           plane_damage_fx__engineDestroyedEffect : string;
                                           plane_damage_fx__enginesEmittersIds : IntList;
                                           plane_damage_fx__additionalFireFxEid : EntityId;
                                           var plane_damage_fx__damageFxEid : EntityId&;
                                           var plane_damage_fx__lastDamagedEnginePartId : int&)
  let nodeId = get_int(plane_damage_fx__damageFxEid, "plane_effect__nodeId") ?? plane_damage_fx__lastDamagedEnginePartId
  if nodeId > -1
    update_engine_damage_fx(nodeId,
                            eid,
                            transform,
                            collres,
                            animchar,
                            aircraft_state_engine__damageStage,
                            fire_damage_state,
                            plane_damage_fx__engineBurningEffect,
                            plane_damage_fx__engineDamagedEffect,
                            plane_damage_fx__engineDestroyedEffect,
                            plane_damage_fx__enginesEmittersIds,
                            plane_damage_fx__additionalFireFxEid,
                            plane_damage_fx__damageFxEid,
                            plane_damage_fx__lastDamagedEnginePartId)


[es(tag=render)]
def plane_damage_fx_update_additional_fire_fx(evt : EventOnPartDamageEffects;
                                              eid : EntityId;
                                              transform : float3x4;
                                              collres : CollisionResource;
                                              animchar : AnimcharBaseComponent;
                                              plane_damage_fx__damageFxEid : EntityId;
                                              plane_damage_fx__additionalFireEffect : string;
                                              var plane_damage_fx__additionalFireFxEid : EntityId&)
  if (evt.effects & (1 << int(DamageEffectType DM_EFFECT_FIRE))) == 0
    return

  let currentMainFxPartId = get_int(plane_damage_fx__damageFxEid, "plane_effect__nodeId") ?? -1
  if currentMainFxPartId == evt.partId
    return

  destroyEntity(plane_damage_fx__additionalFireFxEid)
  plane_damage_fx__additionalFireFxEid = create_damage_fx(-1, collres, evt.partId, transform, animchar, plane_damage_fx__additionalFireEffect, eid)


[es(tag=render, track=fire_damage_state)]
def plane_damage_fx_stop_additional_fire_fx(evt : Event;
                                            fire_damage_state : FireDamageState;
                                            plane_damage_fx__additionalFireFxEid : EntityId)
  query(plane_damage_fx__additionalFireFxEid) <| $ [es] (plane_effect__nodeId : int)
    for state in fire_damage_state.states
      if state.startTime < 0.0 && int(state.partId.id) == plane_effect__nodeId
        destroyEntity(plane_damage_fx__additionalFireFxEid)


[es(tag=render, no_order)]
def plane_effect_update_emitter_pos(info : UpdateStageInfoAct;
                                    plane_effect__planeEid : EntityId;
                                    plane_effect__emitterLocalPos : float3;
                                    plane_effect__minDistSqToUpdateEmitterTm : float;
                                    var plane_effect__emitterPos : float3&;
                                    var effect__velocity : float3&)
  query(plane_effect__planeEid) <| $ [es] (transform : float3x4; animchar__updatable : bool; plane_net_phys : PlaneActor)
    if animchar__updatable
      let emitterPos = transform * plane_effect__emitterLocalPos
      if length_sq(emitterPos - plane_effect__emitterPos) > plane_effect__minDistSqToUpdateEmitterTm
        assume vel = plane_net_phys.phys.currentState.velocity
        effect__velocity = float3(vel.x, vel.y, vel.z)
        plane_effect__emitterPos = emitterPos


[es(tag=render, on_appear, track=plane_effect__emitterPos)]
def plane_effect_update_emitter_tm(evt : Event; plane_effect__planeEid : EntityId; plane_effect__emitterPos : float3; var effect : TheEffect)
  query(plane_effect__planeEid) <| $ [es] (transform : float3x4)
    var emitterTm = transform
    emitterTm[3] = plane_effect__emitterPos
    effect_set_emitter_tm(effect, emitterTm)
