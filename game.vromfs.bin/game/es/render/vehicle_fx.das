require ecs
require ecs.common
require fx
require math.base
require vehicle
require VehicleFx
require AnimV20
require GeomNodeTree
require DagorMath
require DagorSystem
require EnlistedCamera


[es(tag=render, on_appear)]
def exhaust_fx_init_es(evt : Event;
                       animchar : AnimcharBaseComponent;
                       exhaust_fx__fx : string = "";
                       exhaust_fx__brokenFx : string = "";
                       exhaust_fx__emitterNodes : Array;
                       var exhaust_fx : ExhaustFx)
  let fxId = exhaust_fx__fx != "" ? get_type_by_name(exhaust_fx__fx) : -1;
  let fxBrokenId = exhaust_fx__brokenFx != "" ? get_type_by_name(exhaust_fx__brokenFx) : -1

  for node in exhaust_fx__emitterNodes
    let nodeIdStr = node |> get_string("")
    let nodeId = animchar.nodeTree |> geomtree_findNodeIndex(nodeIdStr)
    if nodeId < 0
      continue
    if fxId >= 0
      exhaust_fx.emitters |> push(
        ExhaustFxEmitter(nodeId, ExhaustFxEmitterType REGULAR, fxId))
    if fxBrokenId >= 0
      exhaust_fx.emitters |> push(
        ExhaustFxEmitter(nodeId, ExhaustFxEmitterType DAMAGED, fxBrokenId))


def stop_exhaust_fxs(var exhaust_fx : ExhaustFx)
  for eff in exhaust_fx.emitters
    stop_effect(eff.fx)
  exhaust_fx.haveActiveEmitters = false


[es(tag=render, on_appear, REQUIRE=deadEntity)]
def exhaust_fx_death_es(evt : Event;
                        var exhaust_fx : ExhaustFx)
  stop_exhaust_fxs(exhaust_fx)


[es(tag=render, REQUIRE_NOT=deadEntity, after=update_animchar_visibility_es)]
def exhaust_fx_es(info : UpdateStageInfoAct;
                  transform : float3x4;
                  vehicle_net_phys : VehiclePhysActor;
                  animchar : AnimcharBaseComponent;
                  animchar__visible : bool;
                  exhaust_fx__updateDistSq : float = square(100.0f);
                  var exhaust_fx : ExhaustFx)
  if !animchar__visible
    let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
    let sqDistToCam = distance_sq(cameraTm[3], transform[3])
    if sqDistToCam >= exhaust_fx__updateDistSq
      if exhaust_fx.haveActiveEmitters
        stop_exhaust_fxs(exhaust_fx)
      return
  let velocity = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateVelocity()
  let omega = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateOmega()
  let intensityRaw = vehicle_net_phys.phys.exhaustIntensity
  let intensity = intensityRaw + cvt(intensityRaw, 0.5, 1.0, 0.0, 1.0) * exhaust_fx.exhaustAccumulation
  let mult = saturate(1.0 - exhaust_fx.exhaustAccumulation)
  let exhaustColorMult = Color4(float4(mult, mult, mult, intensity))
  let isEngineBroken = (vehicle_net_phys.phys.engineReadyness <= 0.0)
  assume tree = animchar.nodeTree

  for eff in exhaust_fx.emitters
    if ((eff.exhaustType == ExhaustFxEmitterType DAMAGED) != isEngineBroken)
      stop_effect(eff.fx)
      continue

    var effTm = IDENT_TM
    tree |> geomtree_getNodeWtmScalar(int(eff.nodeId), effTm)
    let dir = effTm[1]
    effTm[1] = effTm[0]
    effTm[0] = dir
    effTm[2] = -effTm[2]
    if eff.fx == null
      eff.fx = start_effect(int(eff.fxTypeId), effTm, IDENT_TM, true)
      exhaust_fx.haveActiveEmitters = true

      if eff.fx != null
        *eff.fx |> lock()
        let scale = max(
          max(length(effTm[0]), length(effTm[1])),
          length(effTm[2]))
        *eff.fx |> setFxScale(scale)
    if eff.fx != null
      let fxLocalVel = effTm[1] * intensity * 1.0 + rotate(effTm, (cross(omega, (inverse(transform) * effTm[3]))))
      let fxFullVel = velocity + fxLocalVel
      *eff.fx |> setVelocity(fxFullVel)
      *eff.fx |> setEmitterTm(effTm, false)
      *eff.fx |> setSpawnRate(saturate(intensity))
      *eff.fx |> setColorMult(exhaustColorMult)

  exhaust_fx.exhaustAccumulation = clamp(exhaust_fx.exhaustAccumulation + (0.2 - 1.0 * square(saturate(intensity))) * info.dt, 0.0, 1.5)