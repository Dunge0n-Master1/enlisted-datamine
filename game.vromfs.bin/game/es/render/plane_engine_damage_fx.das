require ecs
require ecs.common
require enlisted.events_enlisted
require CollRes
require AnimV20
require dm


enum EngineState
  Normal = 0
  Damaged
  Burning
  Destroyed


[es(tag=render, on_appear)]
def plane_engine_damage_fx_on_appear(evt : Event;
                                     damage_model : DamageModel;
                                     plane_engine_damage_fx__emitters : StringList;
                                     var plane_engine_damage_fx__emittersIds : IntList;
                                     var plane_engine_damage_fx__engineStates : IntList;
                                     var plane_engine_damage_fx__fxEids : EidList)
  for nodeName in plane_engine_damage_fx__emitters
    let nodeId = find_part_id_by_name(damage_model, string(nodeName))
    if nodeId > -1
      push(plane_engine_damage_fx__emittersIds, nodeId)

  resize(plane_engine_damage_fx__engineStates, length(plane_engine_damage_fx__emittersIds))
  resize(plane_engine_damage_fx__fxEids, length(plane_engine_damage_fx__emittersIds))


[es(tag=render, on_disappear)]
def plane_engine_damage_fx_on_disappear(evt : Event; plane_engine_damage_fx__fxEids : EidList)
  for fxEid in plane_engine_damage_fx__fxEids
    destroyEntity(fxEid)


[es(tag=render, track=(enginesFire, aircraft_state_engine__damageStage))]
def plane_engine_damage_fx_update(evt : Event;
                                  eid : EntityId;
                                  enginesFire : BoolList;
                                  aircraft_state_engine__damageStage : UInt8List;
                                  plane_engine_damage_fx__emittersIds : IntList;
                                  var plane_engine_damage_fx__engineStates : IntList)
  for i, engineState, engineDamageStage in iter_range(plane_engine_damage_fx__emittersIds), plane_engine_damage_fx__engineStates, aircraft_state_engine__damageStage
    var newEngineState = EngineState Normal

    if engineDamageStage == uint8(2)
      newEngineState = EngineState Destroyed
    elif engineDamageStage == uint8(1)
      newEngineState = EngineState Damaged

    if enginesFire[i]
      newEngineState = EngineState Burning

    if engineState != int(newEngineState)
      sendEvent(eid, [[CmdUpdatePlaneEngineDamageFx engineIndex=i]])

    engineState = int(newEngineState)


[es(tag=render)]
def plane_engine_damage_fx_on_update_fx(evt : CmdUpdatePlaneEngineDamageFx;
                                        eid : EntityId;
                                        transform : float3x4;
                                        collres : CollisionResource;
                                        animchar : AnimcharBaseComponent;
                                        plane_engine_damage_fx__damagedEffect : string;
                                        plane_engine_damage_fx__burningEffect : string;
                                        plane_engine_damage_fx__destroyedEffect : string;
                                        plane_engine_damage_fx__emittersIds : IntList;
                                        plane_engine_damage_fx__engineStates : IntList;
                                        var plane_engine_damage_fx__fxEids : EidList)
  destroyEntity(plane_engine_damage_fx__fxEids[evt.engineIndex])

  let engineState = plane_engine_damage_fx__engineStates[evt.engineIndex]
  if engineState == int(EngineState Normal)
    return

  let effectTemplate = (engineState == int(EngineState Damaged) ? plane_engine_damage_fx__damagedEffect
                     :  engineState == int(EngineState Burning) ? plane_engine_damage_fx__burningEffect
                     :  plane_engine_damage_fx__destroyedEffect)

  let enginePartId = plane_engine_damage_fx__emittersIds[evt.engineIndex]

  var emitterTm : float3x4
  collres_get_collision_node_tm(collres, enginePartId, transform, animchar.nodeTree, emitterTm)

  plane_engine_damage_fx__fxEids[evt.engineIndex] = createEntity(effectTemplate) <| $(var init)
    set(init, "transform", emitterTm)
    set(init, "plane_effect__nodeId", enginePartId)
    set(init, "plane_effect__planeEid", eid)
    set(init, "plane_effect__emitterPos", emitterTm[3])
    set(init, "plane_effect__emitterLocalPos", inverse(transform) * emitterTm[3])


[es(tag=render, track=plane_engine_damage_fx__engineStates)]
def plane_engine_damage_fx_on_track_engine_state(evt : Event;
                                                 plane_engine_damage_fx__engineStates : IntList;
                                                 var plane_engine_damage_fx__isAnyEngineDamaged : bool&;
                                                 var plane_engine_damage_fx__isAnyEngineBurning : bool&)
  plane_engine_damage_fx__isAnyEngineDamaged = false
  plane_engine_damage_fx__isAnyEngineBurning = false
  for state in plane_engine_damage_fx__engineStates
    plane_engine_damage_fx__isAnyEngineDamaged ||= (state != int(EngineState Normal))
    plane_engine_damage_fx__isAnyEngineBurning ||= (state == int(EngineState Burning))
