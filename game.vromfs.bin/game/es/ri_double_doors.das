require ecs
require game.es.events
require RendInst
require DagorMath
require CollRes
require Grid


[es(tag=server, REQUIRE=connectDoubleDoors, on_appear)]
def double_doors_es(evt : Event; eid : EntityId)
  destroyEntity(eid)
  ecs::query() <| $ [es(REQUIRE=isDoor)] (eid : EntityId;
                                          door_operations__openedAngle : float;
                                          door_operations__closedAngle : float;
                                          ri_extra : RiExtraComponent;
                                          transform aka current_transform : float3x4;
                                          var pair_door__eid aka current_pair_door__eid : EntityId&;
                                          pair_door__searchDist : float = 3.0;
                                          pair_door__checkMargin : float = 0.05)
    if pair_door__eid != ecs::INVALID_ENTITY_ID
      return

    var riType = handle_to_ri_type(ri_extra.handle)
    var collres = get_ri_gen_extra_collres(int(riType))
    if collres == null
      return

    let margin = float4(pair_door__checkMargin, pair_door__checkMargin, pair_door__checkMargin, 0.0)
    var extendedBox = collres.vFullBBox
    extendedBox.bmin -= margin
    extendedBox.bmax += margin

    let curDoorOpenedAngle = door_operations__openedAngle
    let curDoorClosedAngle = door_operations__closedAngle
    let curDoorBox = BBox3(extendedBox)

    let bounding = BSphere3(transform[3], pair_door__searchDist)
    find_entity_in_grid(ecs_hash("doors"), bounding, GridEntCheck POS) <| $(pairEid : EntityId)
      if pairEid == eid
        return false

      ecs::query(pairEid) <| $ [es] (door_operations__openedAngle : float;
                                     door_operations__closedAngle : float;
                                     ri_extra : RiExtraComponent;
                                     transform : float3x4;
                                     var pair_door__eid : EntityId&)

        if pair_door__eid != ecs::INVALID_ENTITY_ID
          return
        if door_operations__openedAngle != -curDoorOpenedAngle && door_operations__closedAngle != -curDoorClosedAngle
          return

        riType = handle_to_ri_type(ri_extra.handle)
        collres = get_ri_gen_extra_collres(int(riType))
        if collres == null
          return

        var extendedSecondBox = collres.vFullBBox
        extendedSecondBox.bmin -= margin
        extendedSecondBox.bmax += margin
        let box = BBox3(extendedSecondBox)
        if check_bbox3_intersection(curDoorBox, current_transform, box, transform)
          pair_door__eid = eid
          current_pair_door__eid = pairEid

      return current_pair_door__eid != ecs::INVALID_ENTITY_ID
