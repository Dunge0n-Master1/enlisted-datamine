require ecs
require app
require game.es.events
require pathfinder
require DagorRandom
require DagorMath
require CollRes
require RendInst

def obstacle_door_update(var obstacle__handle : int&;
                         transform : float3x4;
                         rendinst_axis_rotation__targetAngle : float;
                         door_operations__closedAngle : float;
                         ri_extra : RiExtraComponent;
                         obstacle__padding : float;
                         in_progress : bool)
  let isDoorClosed = rendinst_axis_rotation__targetAngle == door_operations__closedAngle
  if isDoorClosed && !in_progress
    tilecache_obstacle_remove(obstacle__handle)
    obstacle__handle = 0
    return

  let riType = handle_to_ri_type(ri_extra.handle)
  let doorCollres = get_ri_gen_extra_collres(int(riType))
  if doorCollres != null
    var box = doorCollres.vFullBBox
    box.bmin.y -= obstacle__padding
    if obstacle__handle == 0
      obstacle__handle = tilecache_obstacle_add(transform, BBox3(box))
    else
      tilecache_obstacle_move(obstacle__handle, transform, BBox3(box))

[es(tag=server, on_appear, on_event=EventLevelLoaded)]
def obstacle_door_created_es(evt : Event;
                             var obstacle__handle : int&;
                             transform : float3x4;
                             rendinst_axis_rotation__targetAngle : float;
                             door_operations__closedAngle : float;
                             ri_extra : RiExtraComponent;
                             isDoor : bool = false;
                             obstacle__padding : float = 0.0f)
  if !isDoor
    return
  obstacle_door_update(obstacle__handle, transform,
    rendinst_axis_rotation__targetAngle, door_operations__closedAngle,
    ri_extra, obstacle__padding, false)

// Update state once rotation is done (i.e. rendinst_axis_rotation.enabled is removed)
[es(tag=server, on_event=EventComponentsDisappear, REQUIRE=rendinst_axis_rotation__enabled)]
def obstacle_door_move_done_es(evt : Event;
                               var obstacle__handle : int&;
                               transform : float3x4;
                               rendinst_axis_rotation__targetAngle : float;
                               door_operations__closedAngle : float;
                               ri_extra : RiExtraComponent;
                               isDoor : bool = false;
                               obstacle__padding : float = 0.0f)
  if !isDoor
    return
  obstacle_door_update(obstacle__handle, transform,
    rendinst_axis_rotation__targetAngle, door_operations__closedAngle,
    ri_extra, obstacle__padding, false)

// When rotation starts, save time, we want to create / update obstacle after a timeout
[es(tag=server, on_appear, REQUIRE=(rendinst_axis_rotation__enabled, door_operations__closedAngle, ri_extra))]
def obstacle_door_move_start_es(evt : Event;
                                var obstacle__lastCheckTime : float&;
                                isDoor : bool = false)
  if !isDoor
    return
  obstacle__lastCheckTime = get_sync_time()

// Update state when rotation is in progress
[es(tag=server, no_order, REQUIRE=rendinst_axis_rotation__enabled)]
def obstacle_door_check_es(info : UpdateStageInfoAct;
                           transform : float3x4;
                           rendinst_axis_rotation__targetAngle : float;
                           door_operations__closedAngle : float;
                           ri_extra : RiExtraComponent;
                           isDoor : bool = false;
                           obstacle__padding : float = 0.0f;
                           obstacle__checkDelta : float;
                           var obstacle__lastCheckTime : float&;
                           var obstacle__handle : int&)
  if !isDoor
    return
  if (info.curTime < obstacle__lastCheckTime + obstacle__checkDelta)
    return
  obstacle__lastCheckTime = info.curTime
  obstacle_door_update(obstacle__handle, transform,
    rendinst_axis_rotation__targetAngle, door_operations__closedAngle,
    ri_extra, obstacle__padding, true)
