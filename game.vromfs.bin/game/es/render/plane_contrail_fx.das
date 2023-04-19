require ecs
require ecs.safe
require math.base
require CollRes
require GamePhys
require Plane
require fx
require DngPlane
require DagorSystem
require DagorMath
require enlisted.events_enlisted


let ZERO_KELVIN_IN_CELSIUM = -273.15


def get_emitter_tm(collres : CollisionResource; node_id : int; plane_tm : float3x4)
  let collNode = collres_get_node(collres, node_id)
  let emitterPos = plane_tm * collNode.tm[3]

  var emitterTm = IDENT_TM
  emitterTm[3] = emitterPos

  return emitterTm


[es(tag=render, on_appear)]
def contrail_fx_on_appear(evt : Event;
                          eid : EntityId;
                          collres : CollisionResource;
                          contrail_fx__emitters : Array;
                          var contrail_fx__engineIndices : IntList;
                          var contrail_fx__nodeIds : IntList;
                          var contrail_fx__fxEids : EidList)
  for i, emitterAttr in iter_range(contrail_fx__emitters), contrail_fx__emitters
    let emitter = emitterAttr as Object
    let engineIndex = emitter?.engineIndex ?? -1
    if engineIndex < 0
      logerr("invalid the 'engineIndex' in the 'contrail_fx__emitters[{i}]' of the '{getEntityTemplateName(eid)}'")

    let nodeId = collres_get_node_index_by_name(collres, emitter?.node ?? "")

    push(contrail_fx__engineIndices, engineIndex)
    push(contrail_fx__nodeIds, nodeId)
    push(contrail_fx__fxEids, INVALID_ENTITY_ID)


[es(tag=render, on_disappear)]
def contrail_fx_on_disappear(evt : Event; var contrail_fx__fxEids : EidList)
  for fxEid in contrail_fx__fxEids
    destroyEntity(fxEid)


[es(tag=render, REQUIRE_NOT=deadEntity)]
def contrail_fx_on_update(evt : ParallelUpdateFrameDelayed;
                          eid : EntityId;
                          collres : CollisionResource;
                          transform : float3x4;
                          contrail_fx__fxTemplate : string;
                          contrail_fx__maxContrailTemperature : float;
                          contrail_fx__minThrottle : float;
                          var contrail_fx__engineIndices : IntList;
                          var contrail_fx__nodeIds : IntList;
                          var contrail_fx__fxEids : EidList;
                          var plane_net_phys : PlaneActor)
  let temperature = atmosphere_temperature(float(plane_net_phys.phys.currentState.location.P.y)) + ZERO_KELVIN_IN_CELSIUM
  let isTempSuitable = temperature < contrail_fx__maxContrailTemperature

  for engineIndex, nodeId, fxEid in contrail_fx__engineIndices, contrail_fx__nodeIds, contrail_fx__fxEids
    if engineIndex < 0 || engineIndex > plane_net_phys.phys.EI.numEngines || nodeId < 0
      continue

    propulsion_get_engine(*plane_net_phys.phys.EI, engineIndex) <| $(engine)
      if !isTempSuitable || engine.stage != EStage E_STAGE_NOMINAL || engine.controlThrottle <= contrail_fx__minThrottle
        destroyEntity(fxEid)
        fxEid = INVALID_ENTITY_ID
        return

      if !!fxEid
        return

      fxEid = createEntity(contrail_fx__fxTemplate) <| $(init)
        set(init, "transform", get_emitter_tm(collres, nodeId, transform))
        set(init, "plane_contrail_effect__planeEid", eid)
        set(init, "plane_contrail_effect__nodeId", nodeId)


[es(tag=render, after=contrail_fx_on_update)]
def contrail_effect_on_update(info : ParallelUpdateFrameDelayed;
                              plane_contrail_effect__planeEid : EntityId;
                              plane_contrail_effect__nodeId : int;
                              var transform aka effect_transform : float3x4&;
                              var effect__velocity : float3&)
  query(plane_contrail_effect__planeEid) <| $ [es] (transform : float3x4;
                                                    collres : CollisionResource;
                                                    plane_net_phys : PlaneActor)
    effect_transform = get_emitter_tm(collres, plane_contrail_effect__nodeId, transform)

    assume planeVel = plane_net_phys.phys.currentState.velocity
    effect__velocity = float3(planeVel.x, planeVel.y, planeVel.z)
