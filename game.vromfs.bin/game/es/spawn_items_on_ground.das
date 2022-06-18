require EnlistedNet
require ecs
require ecs.common
require math.base
require game.es.events
require CollRes
require DagorMath
require DagorConsole
require Dacoll
require DagorMath


def create_next_item(item : Object const?; transform : float3x4; spawner_eid : EntityId; next_idx : int) : int
  let onSpawn <- @ <| (eid : EntityId)
    query(eid) <| $ [es] (var transform : float3x4; collres : CollisionResource)
      let pos = transform[3]
      var height = 10f
      if tracedown_normalized(pos, height, ETF_DEFAULT)
        var bbox = collres.boundingBox
        if bbox |> bbox3_isempty()
          bbox = BBox3(float3(), 0.2)
        transform[3].y -= height - bbox.width.y * 0.5

  let templ = item |> get_string("templ", "")
  let count = item |> get_int("count") ?? 1
  var first = true
  var spawned = 0
  for _ in range(count)
    let eid = createEntity(templ + "+item_grid_spawner_entity", onSpawn) <| $(var init)
      var tm = IDENT_TM
      tm[3] = transform[3]
      init |> set("transform", tm)
      init |> set("gridSpawnerEid", spawner_eid)
      init |> set("grid_spawner__nextIdx", next_idx)
      init |> set("grid_spawner__firstItem", first)
    spawned += !eid ? 0 : 1
    first = false
  return spawned


[es(tag=server, REQUIRE_NOT=spawnItemStep, on_appear)]
def grid_spawn_items(evt : Event; eid : EntityId; transform : float3x4; spawnItemList : Array)
  if length(spawnItemList) == 0
    destroyEntity(eid)
    return
  create_next_item(get_ecs_object(spawnItemList[0]), transform, eid, 1)


[es(tag=server, on_appear)]
def grid_spawn_next_items(evt : Event; eid, gridSpawnerEid : EntityId;
                          grid_spawner__nextIdx : int; grid_spawner__firstItem : bool;
                          var transform aka item_transform : float3x4; collres : CollisionResource)
  remote_recreate_entity_from(eid, remove_sub_template_name(eid, "item_grid_spawner_entity"))
  query(gridSpawnerEid) <| $ [es] (transform : float3x4; spawnItemList : Array;
                                   grid_spawner__gap : float = 0.2;
                                   var grid_spawner__rowHeight : float&)
    var box = BBox3()
    box |> v_bbox3_to_scalar_bbox3(collres.vFullBBox)
    if box |> bbox3_isempty()
      box = BBox3(float3(), 0.2)

    var tm := item_transform
    item_transform[3].x += -box.center.x + box.width.x * 0.5
    item_transform[3].z += -box.center.z + box.width.z * 0.5

    if !grid_spawner__firstItem
      return

    let num = length(spawnItemList)
    if grid_spawner__nextIdx >= num
      destroyEntity(gridSpawnerEid)
      return

    let gridWidth = int(ceil(sqrt(float(num))))
    let prewRow = int((grid_spawner__nextIdx - 1) / gridWidth)
    let curRow = int(grid_spawner__nextIdx / gridWidth)
    if curRow != prewRow
      tm[3].x = transform[3].x
      tm[3].z += grid_spawner__rowHeight
      grid_spawner__rowHeight = 0f
    else
      tm[3].x += box.width.x + grid_spawner__gap
      grid_spawner__rowHeight = max(box.width.z + grid_spawner__gap, grid_spawner__rowHeight)

    for i in range(grid_spawner__nextIdx, num)
      let created = create_next_item(get_ecs_object(spawnItemList[i]), tm, gridSpawnerEid, i + 1)
      if created > 0
        break
