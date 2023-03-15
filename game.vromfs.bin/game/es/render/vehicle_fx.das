require ecs
require ecs.common
require ecs.soa_template
require fx
require math.base
require vehicle
require AnimV20
require GeomNodeTree
require DagorMath
require DagorSystem
require EnlistedCamera
require strings
require enlisted.events_enlisted


enum ExhaustFxEmitterType
  Regular
  Damaged


[soa_template]
struct ExhaustFxEmitter
  exhaust_fx_emitter__nodeId : int
  exhaust_fx_emitter__exhaustType : int
  exhaust_fx_emitter__fxEid : EntityId


[soa_es, es(tag=render, on_appear)]
def exhaust_fx_init_es(evt : Event;
                       animchar : AnimcharBaseComponent;
                       exhaust_fx__fx : string = "";
                       exhaust_fx__brokenFx : string = "";
                       exhaust_fx__emitterNodes : StringList;
                       var exhaustFxEmitter : ExhaustFxEmitter_SOA)
  for node in exhaust_fx__emitterNodes
    peek(node) <| $(nodeName)
      let nodeId = *animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
      if nodeId < 0
        return

      if !empty(exhaust_fx__fx)
        push(exhaustFxEmitter, [[ExhaustFxEmitter
          exhaust_fx_emitter__nodeId=nodeId,
          exhaust_fx_emitter__exhaustType=int(ExhaustFxEmitterType Regular),
          exhaust_fx_emitter__fxEid=INVALID_ENTITY_ID
        ]])
      if !empty(exhaust_fx__brokenFx)
        push(exhaustFxEmitter, [[ExhaustFxEmitter
          exhaust_fx_emitter__nodeId=nodeId,
          exhaust_fx_emitter__exhaustType=int(ExhaustFxEmitterType Damaged),
          exhaust_fx_emitter__fxEid=INVALID_ENTITY_ID
        ]])


[soa_def]
def stop_exhaust_fxs(var exhaustFxEmitter : ExhaustFxEmitter_SOA; var exhaust_fx__haveActiveEmitters : bool&)
  for fx in exhaustFxEmitter
    destroyEntity(fx.exhaust_fx_emitter__fxEid)
    fx.exhaust_fx_emitter__fxEid = INVALID_ENTITY_ID
  exhaust_fx__haveActiveEmitters = false


[soa_es, es(tag=render, on_appear, REQUIRE=deadEntity)]
def exhaust_fx_death_es(evt : Event;
                        var exhaustFxEmitter : ExhaustFxEmitter_SOA;
                        var exhaust_fx__haveActiveEmitters : bool&)
  stop_exhaust_fxs(exhaustFxEmitter, exhaust_fx__haveActiveEmitters)


[soa_es, es(tag=render, on_disappear)]
def exhaust_fx_on_disappear_es(evt : Event;
                               var exhaustFxEmitter : ExhaustFxEmitter_SOA;
                               var exhaust_fx__haveActiveEmitters : bool&)
  stop_exhaust_fxs(exhaustFxEmitter, exhaust_fx__haveActiveEmitters)


def calc_effect_tm(animchar : AnimcharBaseComponent; node_id : int)
  var effTm = IDENT_TM
  geomtree_getNodeWtmScalar(*animchar.nodeTree, node_id, effTm)

  let dir = effTm[1]
  effTm[1] = effTm[0]
  effTm[0] = dir
  effTm[2] = -effTm[2]

  return effTm


def is_engine_broken(vehicle_net_phys : VehiclePhysActor)
  return vehicle_net_phys.phys.engineReadyness <= 0.0


[soa_es, es(tag=render, REQUIRE_NOT=deadEntity)]
def exhaust_fx_control_effects_es(evt : ParallelUpdateFrameDelayed;
                                  transform : float3x4;
                                  vehicle_net_phys : VehiclePhysActor;
                                  animchar : AnimcharBaseComponent;
                                  animchar__visible : bool;
                                  exhaust_fx__fx : string = "";
                                  exhaust_fx__brokenFx : string = "";
                                  exhaust_fx__updateDistSq : float = square(100.0f);
                                  var exhaustFxEmitter : ExhaustFxEmitter_SOA;
                                  var exhaust_fx__haveActiveEmitters : bool&)
  if !animchar__visible
    let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
    let sqDistToCam = distance_sq(cameraTm[3], transform[3])
    if sqDistToCam >= exhaust_fx__updateDistSq
      if exhaust_fx__haveActiveEmitters
        stop_exhaust_fxs(exhaustFxEmitter, exhaust_fx__haveActiveEmitters)
      return

  if !vehicle_net_phys.phys.isICEWorking
    if exhaust_fx__haveActiveEmitters
      stop_exhaust_fxs(exhaustFxEmitter, exhaust_fx__haveActiveEmitters)
    return

  for eff in exhaustFxEmitter
    let isFxTypeDamaged = eff.exhaust_fx_emitter__exhaustType == int(ExhaustFxEmitterType Damaged)
    if isFxTypeDamaged != is_engine_broken(vehicle_net_phys)
      destroyEntity(eff.exhaust_fx_emitter__fxEid)
      eff.exhaust_fx_emitter__fxEid = INVALID_ENTITY_ID
      continue

    if !eff.exhaust_fx_emitter__fxEid
      let effTm = calc_effect_tm(animchar, eff.exhaust_fx_emitter__nodeId)
      let effectTemplate = eff.exhaust_fx_emitter__exhaustType == int(ExhaustFxEmitterType Regular) ? exhaust_fx__fx : exhaust_fx__brokenFx
      eff.exhaust_fx_emitter__fxEid = createEntity(effectTemplate) <| $(var init)
        set(init, "transform", effTm)
        set(init, "effect__scale", max(
          max(length(effTm[0]), length(effTm[1])),
          length(effTm[2])
        ))
      exhaust_fx__haveActiveEmitters = true


[soa_es, es(tag=render, REQUIRE_NOT=deadEntity)]
def exhaust_fx_update_effects_es(evt : ParallelUpdateFrameDelayed;
                                 vehicle_net_phys : VehiclePhysActor;
                                 animchar : AnimcharBaseComponent;
                                 exhaust_fx__minExhaustHeightScale : float;
                                 exhaust_fx__maxExhaustHeightScale : float;
                                 exhaust_fx__minIdleExhaustIntensity : float;
                                 var exhaustFxEmitter : ExhaustFxEmitter_SOA;
                                 var exhaust_fx__exhaustAccumulation : float&)
  let minIntensity = is_engine_broken(vehicle_net_phys) ? 0.0 : exhaust_fx__minIdleExhaustIntensity
  let intensityRaw = max(minIntensity, vehicle_net_phys.phys.exhaustIntensity)
  let intensity = intensityRaw + cvt(intensityRaw, 0.5, 1.0, 0.0, 1.0) * exhaust_fx__exhaustAccumulation

  for eff in exhaustFxEmitter
    query(eff.exhaust_fx_emitter__fxEid) <| $ [es] (var transform : float3x4&;
                                                    var effect__velocity : float3&;
                                                    var effect__spawnRate : float&;
                                                    var effect__colorMult : E3DCOLOR&;
                                                    var effect__distance_scale : float&)
      transform = calc_effect_tm(animchar, eff.exhaust_fx_emitter__nodeId)

      let velocity = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateVelocity()
      let omega = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateOmega()
      let localVelocity = transform[1] * intensity * 1.0 + rotate(transform, (cross(omega, (inverse(transform) * transform[3]))))
      effect__velocity = velocity + localVelocity

      effect__spawnRate = saturate(intensity)
      effect__distance_scale = cvt(vehicle_net_phys.phys.engineRPM,
                                   vehicle_net_phys.phys.engineMinRPM, vehicle_net_phys.phys.engineMaxRPM,
                                   exhaust_fx__minExhaustHeightScale, exhaust_fx__maxExhaustHeightScale)

      let mult = saturate(1.0 - exhaust_fx__exhaustAccumulation)
      let exhaustColorMult = Color4(float4(mult, mult, mult, effect__spawnRate))
      effect__colorMult = E3DCOLOR(exhaustColorMult)

  exhaust_fx__exhaustAccumulation = clamp(exhaust_fx__exhaustAccumulation + (0.2 - 1.0 * square(saturate(intensity))) * evt.dt, 0.0, 1.5)
