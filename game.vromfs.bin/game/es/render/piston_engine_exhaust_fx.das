require ecs
require ecs.safe
require ecs.soa_template
require math.base
require AnimV20
require GeomNodeTree
require Plane
require EnlistedPlane
require enlisted.events_enlisted


let RAD_PER_SEC_TO_RPM = 60.0 / TWOPI


[soa_template]
struct PlanePistonEngineEffects
  plane_piston_engine_effects__nodeId : int
  plane_piston_engine_effects__engineIndex : int
  plane_piston_engine_effects__engineMode : int
  plane_piston_engine_effects__fxEid : EntityId


enum EngineMode
  ENGINE_MODE_NONE = 0
  ENGINE_MODE_START
  ENGINE_MODE_NOMINAL
  ENGINE_MODE_COMBAT
  ENGINE_MODE_WEP
  ENGINE_MODE_MAX


def calc_engine_mode(piston_engine_exhaust_fx__transitionThrottle : float2;
                     plane_net_phys : PlaneActor;
                     engine : Plane::Engine const#)
  if engine.stage == EStage E_STAGE_NULL
    return EngineMode ENGINE_MODE_NONE
  elif !engine_hasFuel(engine, plane_net_phys.phys) || int(engine.stage) > int(EStage E_STAGE_NOMINAL) || int(engine.damageLevel) >= MAX_ENGINE_DAMAGE_LEVEL
    return EngineMode ENGINE_MODE_NONE
  elif int(engine.stage) < int(EStage E_STAGE_NOMINAL)
    return EngineMode ENGINE_MODE_START
  elif engine_isAfterburnerEffective(engine, plane_net_phys.phys.M.nitro)
    return EngineMode ENGINE_MODE_WEP
  elif engine.controlThrottle > piston_engine_exhaust_fx__transitionThrottle.y
    return EngineMode ENGINE_MODE_COMBAT
  else
    return EngineMode ENGINE_MODE_NOMINAL


def get_emitter_tm(geom_node_tree : GeomNodeTree; node_id : int)
  var nodeTm : float3x4
  geomtree_getNodeWtmScalar(geom_node_tree, node_id, nodeTm)

  var emitterTm = IDENT_TM
  emitterTm[3] = nodeTm[3]

  return emitterTm


[soa_es, es(tag=render)]
def piston_engine_exhaust_fx_on_update(info : ParallelUpdateFrameDelayed;
                                       eid : EntityId;
                                       animchar : AnimcharBaseComponent;
                                       piston_engine_exhaust_fx__transitionThrottle : float2;
                                       piston_engine_exhaust_fx__engineModeStartFxTemplate : string;
                                       piston_engine_exhaust_fx__engineModeNominalFxTemplate : string;
                                       piston_engine_exhaust_fx__engineModeCombatFxTemplate : string;
                                       piston_engine_exhaust_fx__engineModeWepFxTemplate : string;
                                       var planePistonEngineEffects : PlanePistonEngineEffects_SOA;
                                       var plane_net_phys : PlaneActor)
  for effect in planePistonEngineEffects
    propulsion_get_engine(*plane_net_phys.phys.EI, effect.plane_piston_engine_effects__engineIndex) <| $(engine)
      let engineMode = calc_engine_mode(piston_engine_exhaust_fx__transitionThrottle, plane_net_phys, engine)

      if effect.plane_piston_engine_effects__engineMode != int(engineMode)
        destroyEntity(effect.plane_piston_engine_effects__fxEid)
        effect.plane_piston_engine_effects__fxEid = INVALID_ENTITY_ID
        effect.plane_piston_engine_effects__engineMode = int(engineMode)

      let fxTemplate = (engineMode == EngineMode ENGINE_MODE_START ? piston_engine_exhaust_fx__engineModeStartFxTemplate
                : engineMode == EngineMode ENGINE_MODE_NOMINAL ? piston_engine_exhaust_fx__engineModeNominalFxTemplate
                : engineMode == EngineMode ENGINE_MODE_COMBAT ? piston_engine_exhaust_fx__engineModeCombatFxTemplate
                : engineMode == EngineMode ENGINE_MODE_WEP ? piston_engine_exhaust_fx__engineModeWepFxTemplate
                : "")

      if effect.plane_piston_engine_effects__fxEid == INVALID_ENTITY_ID && !empty(fxTemplate)
        effect.plane_piston_engine_effects__fxEid = createEntity(fxTemplate) <| $(init)
          set(init, "transform", get_emitter_tm(*animchar.nodeTree, effect.plane_piston_engine_effects__nodeId))
          set(init, "plane_exhaust_effect__planeEid", eid)
          set(init, "plane_exhaust_effect__nodeId", effect.plane_piston_engine_effects__nodeId)
          set(init, "plane_exhaust_effect__engineIndex", effect.plane_piston_engine_effects__engineIndex)
        effect.plane_piston_engine_effects__engineMode = int(engineMode)


[es(tag=render)]
def piston_engine_exhaust_fx_update_effects(info : ParallelUpdateFrameDelayed;
                                            plane_exhaust_effect__planeEid : EntityId;
                                            plane_exhaust_effect__nodeId : int;
                                            plane_exhaust_effect__engineIndex : int;
                                            var transform aka effect_transform : float3x4&;
                                            var effect__velocity : float3&)
  query(plane_exhaust_effect__planeEid) <| $ [es] (transform : float3x4;
                                                   animchar : AnimcharBaseComponent;
                                                   piston_engine_exhaust_fx__rpmToFxSpeed : float;
                                                   var plane_net_phys : PlaneActor)
    propulsion_get_engine(*plane_net_phys.phys.EI, plane_exhaust_effect__engineIndex) <| $(engine)
      effect_transform = get_emitter_tm(*animchar.nodeTree, plane_exhaust_effect__nodeId)

      let fxDir = -transform[0]
      let omegaToFxSpeed = piston_engine_exhaust_fx__rpmToFxSpeed * RAD_PER_SEC_TO_RPM
      effect__velocity = fxDir * engine.omega * omegaToFxSpeed


[soa_es, es(tag=render, on_appear)]
def piston_engine_exhaust_fx_on_appear(evt : Event;
                                       animchar : AnimcharBaseComponent;
                                       piston_engine_exhaust_fx__emitters : Array;
                                       var plane_net_phys : PlaneActor;
                                       var planePistonEngineEffects : PlanePistonEngineEffects_SOA)
  for emitterAttr in piston_engine_exhaust_fx__emitters
    let emitter = emitterAttr as Object
    let engineIndex = emitter?.engineIndex ?? -1
    if engineIndex < 0 || engineIndex >= plane_net_phys.phys.EI.numEngines
      continue

    let emitterNodeName = emitter?.node ?? ""
    let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, emitterNodeName) // geomtree_find__I__NodeIndex
    if nodeId < 0
      continue

    propulsion_get_engine(*plane_net_phys.phys.EI, engineIndex) <| $(engine)
      if engine.typ != EType E_TYPE_INLINE && engine.typ != EType E_TYPE_RADIAL && engine.typ != EType E_TYPE_TURBOPROP
        return

      push(planePistonEngineEffects, [[PlanePistonEngineEffects
        plane_piston_engine_effects__engineIndex=engineIndex,
        plane_piston_engine_effects__engineMode=int(EngineMode ENGINE_MODE_NONE),
        plane_piston_engine_effects__nodeId=nodeId,
        plane_piston_engine_effects__fxEid=INVALID_ENTITY_ID
      ]])


[es(tag=render, on_disappear)]
def piston_engine_exhaust_fx_on_disappear(evt : Event; plane_piston_engine_effects__fxEid : EidList)
  for fxEid in plane_piston_engine_effects__fxEid
    destroyEntity(fxEid)
