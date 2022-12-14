require ecs
require ecs.common
require game.es.events
require AnimV20
require vehicle
require game.es.vehicle.vehicle_events
require DagorSystem
require GeomNodeTree
require EffectorData

[es(tag=render, on_appear)]
def vehicle_seats_effectors_init(evt : Event;
                                 animchar : AnimcharBaseComponent;
                                 [[shared_comp]] vehicle_seats__seats : Array;
                                 var vehicle_seats__effectors : Array)
  if vehicle_seats__seats.empty
    return
  for seat in vehicle_seats__seats
    // get object seat
    let seatObj = get_ecs_object(seat)
    if seatObj == null
      return

    push_to_array(vehicle_seats__effectors) <| $(var obj : Object#)
      let effectors = get_ecs_object(seatObj, "effectors")
      let cockpitTemplate = get_string(seatObj, "cockpitTemplate", "")
      if effectors == null || cockpitTemplate != ""
        return
      for field in *effectors
        let nodeValue = get_string(field.value, "")
        if nodeValue == ""
          logerr("can't find node for {field.key}")
          continue
        let index = geomtree_findNodeIndex(*animchar.nodeTree, nodeValue)
        if index < 0
          logerr("can't find node index for {field.key} equal {nodeValue}")
          continue
        set(obj, field.key, index)


[es(tag=render, before=animchar_effectors_update_es, after=human_anim_es)]
def human_vehicle_effectors(info : UpdateStageInfoAct;
                            animchar : AnimcharBaseComponent;
                            vehicle_seats__effectors : Array;
                            vehicle_seats__seatEids : EidList;
                            transform : float3x4)
  if vehicle_seats__effectors.empty
    return
  let vehicleTm = transform
  var vehicleRootTm : float3x4
  geomtree_getNodeWtmRelScalar(*animchar.nodeTree, 0, vehicleRootTm)
  for seatOwnerNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    query(ownerEid) <| $ [es] (var animchar_effectors__effectorsState : Object; transform : float3x4)
      let effectors = get_ecs_object(vehicle_seats__effectors[seatOwnerNo])
      if effectors == null
        return
      for field in *effectors
        let effectorName = field.key
        let effectorIndex = *get_int(*effectors, effectorName)
        var effector = getNullableRW_EffectorData(animchar_effectors__effectorsState, effectorName)

        if effector == null
          return

        let vehicleWofs = geomtree_calc_optimal_wofs(vehicleTm[3])
        let d_wofs = vehicleWofs - geomtree_calc_optimal_wofs(transform[3])

        var vehicleLocalWtm = vehicleTm
        vehicleLocalWtm[3] = vehicleTm[3] - vehicleWofs
        geomtree_getNodeWtmRelScalar(*animchar.nodeTree, effectorIndex, effector.wtm)
        effector.wtm = vehicleLocalWtm * (inverse(vehicleRootTm) * effector.wtm)
        effector.position = effector.wtm[3] + d_wofs
        effector.weight = 1.f
        effector.wtm[3] = effector.position
