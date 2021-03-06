require ecs
require inventory
require GridCollision
require GeomNodeTree
require DagorMath
require AnimV20
require math.base


[es(after=human_visibility_tracer_es, before=human_inventory_hero_es, tag=(ui, render, gameClient), REQUIRE=watchedByPlr, REQUIRE_NOT=deadEntity)]
def items_around_es(info : UpdateStageInfoAct;
                    var itemsAround : ecs::Array;
                    transform : float3x4;
                    human_inventory__lookNodeId : int;
                    animchar : AnimcharBaseComponent;
                    human_inventory__pickupDistance : float = 2.5f;
                    human__canPickupItems : bool = false)
  itemsAround |> clear()

  if !human__canPickupItems
    return
  var queryPos = transform[3]
  if human_inventory__lookNodeId >= 0
    queryPos = geomtree_getNodeWpos(animchar.nodeTree, human_inventory__lookNodeId)

  query() <| $ [es] (eid : EntityId; transform : float3x4; item__visible : bool; animchar_render__enabled : bool = true)
    let distSq = length_sq(queryPos - transform[3])
    if distSq < square(human_inventory__pickupDistance) && animchar_render__enabled && item__visible
      itemsAround |> push(eid)

    query(eid) <| $ [es] (entitiesContainerContent : EidList)
      for itemEid in entitiesContainerContent
        let cont_item_visible = get_bool(itemEid, "animchar_render__enabled") ?? true
        if cont_item_visible
          itemsAround |> push(itemEid)


[es(on_event=EventComponentsDisappear, tag=(ui, render, gameClient), REQUIRE=watchedByPlr, REQUIRE_NOT=deadEntity)]
def clear_items_around_es(evt : Event; var itemsAround : ecs::Array)
  itemsAround |> clear()
