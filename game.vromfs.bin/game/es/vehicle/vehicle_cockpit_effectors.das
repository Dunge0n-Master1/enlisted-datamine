require ecs
require ecs.safe
require ecs.common
require AnimV20
require DagorSystem
require GeomNodeTree
require EffectorData


[es(tag=render, on_appear)]
def cockpit_effectors_init_es(evt : Event;
                              animchar : AnimcharBaseComponent;
                              cockpit__effectorsInfo : Object;
                              var cockpit__effectors : Object)
  for field in cockpit__effectorsInfo
    let nodeValue = get_string(field.value, "")
    if nodeValue == ""
      logerr("Cockpit effector can't find node for {field.key}")
      continue
    let index = geomtree_findNodeIndex(*animchar.nodeTree, nodeValue)
    if index < 0
      logerr("Cockpit effector can't find node index for {field.key} equal {nodeValue}")
      continue
    set(cockpit__effectors, field.key, index)


[es(tag=render, on_disappear)]
def human_vehicle_cockpit_effectors_reset(evt : Event;
                                          cockpit__effectors : Object)
  query() <| $ [es(REQUIRE=hero)] (var animchar_effectors__effectorsState : Object)
    for field in cockpit__effectors
      let effectorName = field.key
      let effectorIndex = cockpit__effectors[effectorName] ?? -1
      if effectorIndex < 0
        return
      var effector = getNullableRW_EffectorData(animchar_effectors__effectorsState, effectorName)

      if effector == null
        continue

      effector.weight = 0.0


[es(tag=render, before=animchar_effectors_update_es, after=(human_anim_es, plane_anim_es))]
def human_vehicle_cockpit_effectors(info : UpdateStageInfoAct;
                                    animchar aka cockpit_animchar : AnimcharBaseComponent;
                                    cockpit__vehicleEid : EntityId;
                                    cockpit__effectors : Object;
                                    cockpit__offset : float3)
  query() <| $ [es(REQUIRE=hero)] (var animchar_effectors__effectorsState : Object; transform : float3x4)
    var cockpitRootTm : float3x4
    var vehicleTransform : float3x4
    query(cockpit__vehicleEid) <| $ [es] (transform : float3x4)
      vehicleTransform = transform
    geomtree_getNodeWtmRelScalar(*cockpit_animchar.nodeTree, 0, cockpitRootTm)
    cockpitRootTm[3] = cockpitRootTm * -cockpit__offset
    for field in cockpit__effectors
      let effectorName = field.key
      let effectorIndex = cockpit__effectors[effectorName] ?? -1
      if effectorIndex < 0
        return
      var effector = getNullableRW_EffectorData(animchar_effectors__effectorsState, effectorName)

      if effector == null
        continue

      let vehicleWofs = geomtree_calc_optimal_wofs(vehicleTransform[3])
      let dWofs = vehicleWofs - geomtree_calc_optimal_wofs(transform[3])

      var vehicleLocalWtm = vehicleTransform
      vehicleLocalWtm[3] = vehicleTransform[3] - vehicleWofs
      geomtree_getNodeWtmRelScalar(*animchar.nodeTree, effectorIndex, effector.wtm)
      effector.wtm = vehicleLocalWtm * (inverse(cockpitRootTm) * effector.wtm)
      effector.position = effector.wtm[3] + dWofs
      effector.weight = 1.f
      effector.wtm[3] = effector.position
