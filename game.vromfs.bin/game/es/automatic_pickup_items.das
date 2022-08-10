require ecs
require inventory
require math
require math.base
require game.es.events
require enlisted.events_enlisted

[es(tag=gameClient, REQUIRE=hero, no_order)]
def automatic_pickup_items_es(info : ParallelUpdateFrameDelayed;
                              eid : EntityId; transform : float3x4;
                              var auto_pickup__lastTime : float&;
                              auto_pickup__delta : float;
                              human__canPickupItems, isAlive, isDowned : bool)
  let canPickup = human__canPickupItems && isAlive && !isDowned
  if !canPickup || info.curTime - auto_pickup__lastTime < auto_pickup__delta
    return
  auto_pickup__lastTime = info.curTime
  let heroPos = transform[3]
  let hero = eid
  ecs::find_query() <| $ [es(REQUIRE=traceVisibility)] (eid, item__lastOwner : EntityId; transform : float3x4; item__automaticPickupRange : float)
    if item__lastOwner != hero && inventory::is_item_useful(hero, eid) && square(item__automaticPickupRange) > length_sq(transform[3] - heroPos)
      inventory::pickup_item(hero, eid)
      return true
    return false

[es(tag=gameClient, REQUIRE=hero)]
def pickup_common_items_es(evt : CmdInventoryPickup; eid : EntityId; transform : float3x4)
  let hero = eid
  let heroPos = transform[3]
  ecs::query(evt.itemEid) <| $ [es(REQUIRE=item__commonPickupRange)] (eid : EntityId; item__id : int)
    let firstItemId = item__id
    let firstItemEid = eid
    ecs::query() <| $ [es(REQUIRE=traceVisibility)] (item__commonPickupRange : float; eid : EntityId; item__id : int; transform : float3x4)
      if firstItemEid != eid && firstItemId == item__id && square(item__commonPickupRange) > length_sq(transform[3] - heroPos)
        inventory::pickup_item(hero, eid)

