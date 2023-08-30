require ecs
require ecs.safe
require ecs.common
require AnimV20
require DagorSystem
require GeomNodeTree
require EffectorData
require enlisted.events_enlisted
require game.events_game

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

[es(tag=render)]
def reset_cockpit_effectors_on_soldier_death(evt : EventEntityDied; human_anim__vehicleSelected : EntityId; var animchar_effectors__effectorsState : Object)
  let cockpit = get_Eid(human_anim__vehicleSelected, "cockpit__eid") ?? INVALID_ENTITY_ID
  query(cockpit) <| $ [es] (cockpit__effectors : Object)
    for field in cockpit__effectors
      let effectorName = field.key
      let effectorIndex = cockpit__effectors[effectorName] ?? -1
      if effectorIndex < 0
        return
      var effector = getNullableRW_EffectorData(animchar_effectors__effectorsState, effectorName)

      if effector == null
        continue

      effector.weight = 0.0

def for_each_effector(var animchar_effectors__effectorsState : Object&;
                      cockpit__effectors : Object;
                      blk : block<(var effector_data : EffectorData&; effector_index : int)>)
  for field in cockpit__effectors
    let effectorName = field.key
    let effectorIndex = cockpit__effectors[effectorName] ?? -1
    if effectorIndex < 0
      return
    var effector = getNullableRW_EffectorData(animchar_effectors__effectorsState, effectorName)

    if effector == null
      continue

    invoke(blk, *effector, effectorIndex)


[es(tag=render, before=before_animchar_update_sync, after=(human_anim_es, plane_anim_es))]
def human_vehicle_cockpit_effectors(info : ParallelUpdateFrameDelayed;
                                    animchar aka cockpit_animchar : AnimcharBaseComponent;
                                    cockpit__vehicleEid : EntityId;
                                    cockpit__effectors : Object;
                                    cockpit__offset : float3)
  query() <| $ [es(REQUIRE=hero)] (transform : float3x4;
                                   isAlive : bool;
                                   human_vehicle__exitAtTime : float = -1.0;
                                   var animchar_effectors__effectorsState : Object&)
    if !isAlive
      return
    if human_vehicle__exitAtTime > info.curTime
      animchar_effectors__effectorsState |> for_each_effector(cockpit__effectors) <| $ [unused_argument(index)] (effector; index)
        effector.weight = 0.0
      return

    var cockpitRootTm : float3x4
    var vehicleTransform : float3x4
    query(cockpit__vehicleEid) <| $ [es] (transform : float3x4)
      vehicleTransform = transform
    geomtree_getNodeWtmRelScalar(*cockpit_animchar.nodeTree, 0, cockpitRootTm)
    cockpitRootTm[3] = cockpitRootTm * -cockpit__offset

    animchar_effectors__effectorsState |> for_each_effector(cockpit__effectors) <| $(effector; index)
      let vehicleWofs = geomtree_calc_optimal_wofs(vehicleTransform[3])
      let dWofs = vehicleWofs - geomtree_calc_optimal_wofs(transform[3])

      var vehicleLocalWtm = vehicleTransform
      vehicleLocalWtm[3] = vehicleTransform[3] - vehicleWofs
      geomtree_getNodeWtmRelScalar(*animchar.nodeTree, index, effector.wtm)
      effector.wtm = vehicleLocalWtm * (inverse(cockpitRootTm) * effector.wtm)
      effector.position = effector.wtm[3] + dWofs
      effector.weight = 1.f
      effector.wtm[3] = effector.position
