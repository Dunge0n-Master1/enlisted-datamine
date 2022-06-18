module inventory_common shared
require ecs
require ecs.common
require inventory
require DagorMath
require DagorMathUtils
require EnlistedHuman
require HumanPhys
require AnimV20
require CollRes
require Dacoll

def push_item_in_cont(owner_eid : EntityId; name : string)
  return createEntity(name) <| $(var init : ComponentsInitializer)
    set(init, "item__ownerEid", owner_eid)

def remove_item_from_cont(eid : EntityId; var itemContainer : EidList&) : bool
  let idx = find_index(itemContainer, eid)
  if idx == -1
    return false
  itemContainer |> erase(idx)
  return true

struct ItemPickupScore
  score : float
  useful : bool


def get_item_pickup_score(eid, item_eid : EntityId; view_convex : Point4List; view_itm : float3x4; aimDir, aimFrom, aimTo, minPickupBox : float3; was_selected : bool) : ItemPickupScore
  var ret = [[ItemPickupScore score=-1.0, useful=false]]
  ecs::query(item_eid) <| $ [es] (animchar_render__enabled : bool = true;
                                  item__lastOwner : EntityId;
                                  item__equipToSlots : ecs::Array?;
                                  var transform : float3x4 const?;
                                  collres : CollisionResource?;
                                  animchar : AnimcharBaseComponent;
                                  animchar_render : AnimcharRendComponent;
                                  item__id : int = INVALID_ITEM_ID;
                                  item_pickup_priority__lookAtWeight : float = 4.f;
                                  item_pickup_priority__usefulWeight : float = 2.f;
                                  item_pickup_priority__angleWeight : float = 1.f;
                                  item_pickup_priority__useCollresMinWidth : float = 1.5f;
                                  item__visible : bool = true;
                                  container__destroyEmpty = true)
    if !animchar_render__enabled || !item__visible
      return
    if item__id == INVALID_ITEM_ID && item__equipToSlots == null
      if !container__destroyEmpty
        ret.score = 0.01 // very small score for not destroyed loot container
      return

    if transform == null
      transform = get_TMatrix(item__lastOwner, "transform")
    if transform == null
      return

    var lbb = BBox3()
    scene_instance_get_local_bounding_box(animchar_render.sceneInstance, lbb)
    lbb |> bbox3_add(minPickupBox)
    lbb |> bbox3_add(-minPickupBox)
    let entPos = (*transform) * lbb.center
    let checkPos = view_itm * entPos
    for plane in view_convex
      let dist = distance_plane_point3(plane, checkPos)
      if dist > 0.0
        ret.score = -1.0
        return

    ret.score = dot(normalize(entPos - aimFrom), aimDir) * item_pickup_priority__angleWeight

    let width = lbb.width
    if collres == null || width.x + width.y + width.z < item_pickup_priority__useCollresMinWidth
      let itemItm = inverse(*transform)
      let from = itemItm * aimFrom
      let to = itemItm * aimTo
      if test_segment_box_intersection(from, to, lbb)
        ret.score += item_pickup_priority__lookAtWeight
    else
      var t = 10f
      var norm : float3
      if collres_traceray(*collres, *transform, animchar.nodeTree, aimFrom, aimDir, t, norm)
        ret.score += item_pickup_priority__lookAtWeight

    ret.useful = is_item_useful(eid, item_eid)
    if ret.useful
      ret.score += item_pickup_priority__usefulWeight

    let selectedItemBias = 0.05
    if was_selected
      ret.score += selectedItemBias

  return ret
