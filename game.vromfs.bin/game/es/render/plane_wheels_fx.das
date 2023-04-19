require ecs
require math.base
require AnimV20
require GeomNodeTree
require DagorMath
require fx
require Plane
require DngPlane
require enlisted.events_enlisted


enum FxType
  Dust
  Friction


def stop(var fx_eid : EntityId&)
  destroyEntity(fx_eid)
  fx_eid = INVALID_ENTITY_ID


def update_effect(plane_eid : EntityId;
                  animchar : AnimcharBaseComponent;
                  node_id : int;
                  fx_type : FxType;
                  fx_template : string;
                  var fx_eid : EntityId&)
  let nodeFxType = get_int(fx_eid, "plane_ground__fxType") ?? -1
  if nodeFxType > -1 && nodeFxType != int(fx_type)
    stop(fx_eid)

  if !fx_eid
    var emitterTm = IDENT_TM
    emitterTm[3] = geomtree_getNodeWpos(*animchar.nodeTree, node_id)

    fx_eid = createEntity(fx_template) <| $(init)
      set(init, "transform", emitterTm)
      set(init, "plane_ground__fxType", int(fx_type))
      set(init, "plane_effect__nodeId", node_id)
      set(init, "plane_effect__planeEid", plane_eid)
      set(init, "plane_effect__emitterPos", emitterTm[3])


[es(tag=render, no_order)]
def plane_wheel_fx_on_update(info : UpdateStageInfoAct;
                             eid : EntityId;
                             plane_net_phys : PlaneActor;
                             animchar : AnimcharBaseComponent;
                             plane_wheel_fx__wheelAngularAccelMin : float;
                             plane_wheel_fx__wheelDustFxTemplate : string;
                             plane_wheel_fx__wheelFrictionFxTemplate : string;
                             plane_wheel_fx__nodeIds : IntList;
                             var plane_wheel_fx__dustFxEids : EidList;
                             var plane_wheel_fx__frictionFxEids : EidList)
  if plane_net_phys.phys.appliedCT.gear <= 0.9 || plane_net_phys.phys.currentAlt >= 20.0
    return
  if plane_net_phys.phys.Gears == null
    return

  assume gear = *plane_net_phys.phys.Gears
  assume gearOutput = gear.output

  let firstGearPart = int(GearPart GEAR_PART_GEAR_FIRST)
  let lastGearPart = int(GearPart GEAR_PART_GEAR_LAST)

  for gearPart in range(firstGearPart, lastGearPart + 1)
    if gear.props.collisionPointsMap[gearPart] < 0
      continue

    let gearIndex = gearPart - firstGearPart

    let nodeId = plane_wheel_fx__nodeIds[gearIndex]
    if (nodeId < 0)
      continue

    assume dustFxEid = plane_wheel_fx__dustFxEids[gearIndex]
    if gearOutput.wheelOnGround[gearIndex] && !gearOutput.hasWater
      update_effect(eid, animchar, nodeId, FxType Dust, plane_wheel_fx__wheelDustFxTemplate, dustFxEid)
    else
      stop(dustFxEid)

    assume frictionFxEid = plane_wheel_fx__frictionFxEids[gearIndex]
    let wheelAngularAcceleration = gearOutput.wheelAngularAcceleration[gearIndex]
    if wheelAngularAcceleration > plane_wheel_fx__wheelAngularAccelMin && !gearOutput.hasWater && gearOutput.isNearGround
      update_effect(eid, animchar, nodeId, FxType Friction, plane_wheel_fx__wheelFrictionFxTemplate, frictionFxEid)
    else
      stop(frictionFxEid)


[es(tag=render, on_appear)]
def plane_wheel_fx_on_appear(evt : Event;
                             animchar : AnimcharBaseComponent;
                             plane_wheel_fx__emitters : StringList;
                             var plane_wheel_fx__nodeIds : IntList;
                             var plane_wheel_fx__dustFxEids : EidList;
                             var plane_wheel_fx__frictionFxEids : EidList)
  resize(plane_wheel_fx__nodeIds, MAX_GEAR_STRUTS)
  for nodeId in plane_wheel_fx__nodeIds
    nodeId = -1

  resize(plane_wheel_fx__dustFxEids, MAX_GEAR_STRUTS)
  resize(plane_wheel_fx__frictionFxEids, MAX_GEAR_STRUTS)

  for emitterIdx, emitterName in iter_range(plane_wheel_fx__emitters), plane_wheel_fx__emitters
    peek(emitterName) <| $(name)
      let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, name)
      plane_wheel_fx__nodeIds[emitterIdx] = nodeId


[es(tag=render, on_disappear)]
def plane_wheel_fx_on_disappear(evt : Event;
                                var plane_wheel_fx__dustFxEids : EidList;
                                var plane_wheel_fx__frictionFxEids : EidList)
  for dustFxEid, frictionFxEid in plane_wheel_fx__dustFxEids, plane_wheel_fx__frictionFxEids
    stop(dustFxEid)
    stop(frictionFxEid)


[es(tag=render, REQUIRE=plane_ground__fxType)]
def plane_wheels_update_effect_emitter_pos(evt : ParallelUpdateFrameDelayed;
                                           plane_effect__nodeId : int;
                                           plane_effect__planeEid : EntityId;
                                           plane_effect__minDistSqToUpdateEmitterTm : float;
                                           var plane_effect__emitterPos : float3&)
  if plane_effect__nodeId < 0
    return

  query(plane_effect__planeEid) <| $ [es] (animchar__updatable : bool;
                                           animchar : AnimcharBaseComponent)
    if !animchar__updatable
      return

    let emitterPos = geomtree_getNodeWpos(*animchar.nodeTree, plane_effect__nodeId)
    if length_sq(emitterPos - plane_effect__emitterPos) > plane_effect__minDistSqToUpdateEmitterTm
      plane_effect__emitterPos = emitterPos


[es(tag=render, REQUIRE=plane_ground__fxType)]
def plane_wheels_update_ground_effect_spawn_rate(evt : ParallelUpdateFrameDelayed;
                                                 plane_effect__planeEid : EntityId;
                                                 plane_ground__spawnRateByVelocity : float4;
                                                 var effect__spawnRate : float&)
  assume spawnRateByVelocity = plane_ground__spawnRateByVelocity

  query(plane_effect__planeEid) <| $ [es] (plane_net_phys : PlaneActor)
    let velLen = length(plane_net_phys.phys.currentState.velocity)
    effect__spawnRate = cvt(velLen, spawnRateByVelocity.x, spawnRateByVelocity.y, spawnRateByVelocity.z, spawnRateByVelocity.w)
