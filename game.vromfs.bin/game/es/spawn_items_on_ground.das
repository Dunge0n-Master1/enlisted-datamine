require EnlistedNet
require ecs
require ecs.safe
require ecs.common
require math.base
require game.es.events
require CollRes
require DagorMath
require DagorConsole
require Dacoll
require DagorMath


def create_next_item(item : Object const?; transform : float3x4; spawner_eid : EntityId; next_idx : int) : int
  let templ = item?.templ ?? ""
  let count = item?.count ?? 1
  var first = true
  var spawned = 0
  for _ in range(count)
    let eid = createEntity(templ + "+item_grid_spawner_entity") <| $(var init)
      var tm = IDENT_TM
      tm[3] = transform[3]
      init |> set("transform", tm)
      init |> set("grid_spawner__ownerEid", spawner_eid)
      init |> set("grid_spawner__nextIdx", next_idx)
      init |> set("grid_spawner__firstItem", first)
    spawned += !eid ? 0 : 1
    first = false
  return spawned


[es(tag=server, on_appear, REQUIRE_NOT=(spawnItemStep, grid_spawner__nextIdx))]
def appear_grid_spawn_items(evt : Event; eid : EntityId; transform : float3x4; spawnItemList : Array)
  if length(spawnItemList) == 0
    destroyEntity(eid)
    return
  create_next_item(get_ecs_object(spawnItemList[0]), transform, eid, 1)


[es(tag=server, on_appear, before=appear_grid_spawn_items)]
def grid_spawner_width(evt : Event; spawnItemList : Array; var grid_spawner__gridWidth : int&)
  if grid_spawner__gridWidth <= 0
    grid_spawner__gridWidth = spawnItemList |> length() |> float() |> sqrt() |> ceil() |> int()


[es(tag=server, on_appear)]
def sub_grid_spawn(evt : Event; eid : EntityId; transform : float3x4;
                   grid_spawner__ownerEid : EntityId;
                   grid_spawner__nextIdx : int;
                   var spawnItemList aka childspawnItemList : Array&)
  query(grid_spawner__ownerEid) <| $ [es] (var spawnItemList aka parentspawnItemList : Array&)
    parentspawnItemList |> erase(grid_spawner__nextIdx - 1)
    for it in childspawnItemList
      parentspawnItemList |> push(it)
    childspawnItemList |> clear()
    eid |> destroyEntity()

    let num = length(parentspawnItemList)
    if grid_spawner__nextIdx >= num
      destroyEntity(grid_spawner__ownerEid)
      return
    for i in range(grid_spawner__nextIdx, num)
      pass
      let created = create_next_item(get_ecs_object(parentspawnItemList[i]), transform, grid_spawner__ownerEid, i + 1)
      if created > 0
        break


[es(tag=server, on_appear)]
def grid_spawn_next_items(evt : Event; eid, grid_spawner__ownerEid : EntityId;
                          grid_spawner__nextIdx : int; grid_spawner__firstItem : bool;
                          var transform aka item_transform : float3x4; collres : CollisionResource)
  remote_recreate_entity_from(eid, remove_sub_template_name(eid, "item_grid_spawner_entity"))

  var height = 30f
  let pos = item_transform[3] + float3(0., 1.5, 0.5)
  if tracedown_normalized(pos, height, ETF_ALL)
    var bbox = collres.boundingBox
    if bbox |> bbox3_isempty()
      bbox = BBox3(float3(), 0.2)
    item_transform[3].y = pos.y - height + bbox.width.y * 0.5 + 0.25

  query(grid_spawner__ownerEid) <| $ [es] (transform : float3x4; spawnItemList : Array;
                                           grid_spawner__gap : float = 0.2;
                                           grid_spawner__gridWidth : int;
                                           var grid_spawner__rowHeight : float&)
    var box = BBox3()
    box |> bbox3f_to_scalar_bbox3(collres.vFullBBox)
    if box |> bbox3_isempty()
      box = BBox3(float3(), 0.2)

    var tm := item_transform
    item_transform[3].x += -box.center.x + box.width.x * 0.5
    item_transform[3].z += -box.center.z + box.width.z * 0.5

    if !grid_spawner__firstItem
      return

    let num = length(spawnItemList)
    if grid_spawner__nextIdx >= num
      destroyEntity(grid_spawner__ownerEid)
      return

    let prewRow = int((grid_spawner__nextIdx - 1) / grid_spawner__gridWidth)
    let curRow = int(grid_spawner__nextIdx / grid_spawner__gridWidth)
    if curRow != prewRow
      tm[3].x = transform[3].x
      tm[3].z += grid_spawner__rowHeight
      grid_spawner__rowHeight = 0f
    else
      tm[3].x += box.width.x + grid_spawner__gap
      grid_spawner__rowHeight = max(box.width.z + grid_spawner__gap, grid_spawner__rowHeight)

    for i in range(grid_spawner__nextIdx, num)
      let created = create_next_item(get_ecs_object(spawnItemList[i]), tm, grid_spawner__ownerEid, i + 1)
      if created > 0
        break
