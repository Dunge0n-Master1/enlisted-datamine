require ecs
require vehicle
require CollRes
require AnimV20
require math.base
require GeomNodeTree

[es(after=vehicle_phys_es, REQUIRE_NOT=deadEntity, before=after_net_phys_sync, on_event=UpdatePhysEvent)]
def vehicle_movable_collision_es(evt : Event;
                                 animchar__updatable : bool;
                                 collres : CollisionResource;
                                 transform : float3x4;
                                 animchar : AnimcharBaseComponent;
                                 vehicle_net_phys : VehiclePhysActor)
  if !animchar__updatable
    return
  for i in range(length(vehicle_net_phys.phys.collNodeIdToCollObjId))
    let objId = vehicle_net_phys.phys.collNodeIdToCollObjId[i]
    if objId >= 0
      var nodeTm : float3x4
      let node = collres_get_node(collres, i)
      collres_get_collision_node_tm(collres, i, IDENT_TM, animchar.nodeTree, nodeTm)
      nodeTm = nodeTm * node.tm
      nodeTm[3] = transform[3]
      vehicle_net_phys.phys |> vehicle_phys_setCollisionObjectTm(objId, nodeTm);
