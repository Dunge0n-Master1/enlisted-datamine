require ecs
require math.base
require inventory
require DngCamera
require GridCollision
require GeomNodeTree
require AnimV20
require HumanPhys
require DagorMath
require enlisted.events_enlisted


[es(after=items_around_es, before=human_inventory_hero_es, tag=(ui, render, gameClient), REQUIRE=watchedByPlr)]
def dead_body_items_around_es(info : ParallelUpdateFrameDelayed;
                              eid : EntityId;
                              human_inventory__lookNodeId : int;
                              animchar : AnimcharBaseComponent;
                              human_inventory__pickupDistance : float = 2.5f;
                              var itemsAround : EidList)
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTm == null
    return
  var queryPos = (*camTm)[3]
  if human_inventory__lookNodeId >= 0
    queryPos = geomtree_getNodeWpos(*animchar.nodeTree, human_inventory__lookNodeId)

  let heroEid = eid

  ecs::query() <| $ [es(REQUIRE=lootable, REQUIRE_NOT=lootableGunOnly)] (eid : EntityId;
                                                                         isAlive : bool = true;
                                                                         transform : float3x4;
                                                                         itemContainer : EidList;
                                                                         human_weap__gunEids : EidList)
    if heroEid == eid || isAlive || distance_sq(queryPos, transform[3]) > square(human_inventory__pickupDistance)
      return
    if !is_item_visible(queryPos, transform[3])
      return

    for itemEid in itemContainer
      let lastOwner = get_Eid(itemEid, "item__lastOwner") ?? INVALID_ENTITY_ID
      if lastOwner != INVALID_ENTITY_ID
        itemsAround |> push(itemEid)

    for gunEid in human_weap__gunEids
      if has(gunEid, "gun") && !has(gunEid, "grenade_thrower")
        itemsAround |> push(gunEid)

  ecs::query() <| $ [es(REQUIRE=lootable, REQUIRE=lootableGunOnly)] (eid : EntityId;
                                                                     isAlive : bool = true;
                                                                     transform : float3x4;
                                                                     human_weap__gunEids : EidList)
    if heroEid == eid || isAlive || distance_sq(queryPos, transform[3]) > square(human_inventory__pickupDistance)
      return
    if !is_item_visible(queryPos, transform[3])
      return

    let gunEid = human_weap__gunEids[int(HUWeaponSlots EWS_PRIMARY)]
    if gunEid != INVALID_ENTITY_ID
      itemsAround |> push(gunEid)
