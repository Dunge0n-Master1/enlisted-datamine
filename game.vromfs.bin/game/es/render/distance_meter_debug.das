options no_aot
require ecs
require strings
require DagorConsole
require DagorDebug3D
require DagorSystem
require game.es.input.input_events
require Dacoll
require PhysMat
require pathfinder
require enlisted.events_enlisted
require DagorInput


[console_cmd(name="distance.meter", hint="Measure distance between points and sum distance of the path; shoot to add or delete point, reload to delete all points")]
def distance_meter_command(nav_mesh = false)
  var found = false
  query() <| $ [es(REQUIRE=distanceMeterDebug)] (eid : EntityId; var distance_meter__navmeshMode : bool&)
    if nav_mesh == distance_meter__navmeshMode
      destroyEntity(eid)
    else
      distance_meter__navmeshMode = nav_mesh
    found = true
  if !found
    createEntity("distance_meter_debug")  <| $(init)
      init |> set("distance_meter__navmeshMode", nav_mesh)
  console_print("{found ? "deactivate" : "activate"} distance meter debug")


def findClosestPointToCameraTrace(points : Point3List;
                                  threshold : float;
                                  cameraPos : float3;
                                  cameraDir : float3)
  var closestPointIdx = -1
  for i, point in iter_range(points), points
    let angleCos = dot(normalize(point - cameraPos), cameraDir)
    if angleCos > 1. - threshold
      if closestPointIdx == -1 || angleCos > dot(normalize(points[closestPointIdx] - cameraPos), cameraDir)
        closestPointIdx = i
  return closestPointIdx


[es(tag=render, before=distance_meter_input, REQUIRE=distanceMeterDebug)]
def distance_meter_update_es(info : ParallelUpdateFrameDelayed;
                             var distance_meter__traceFrom : float3&;
                             var distance_meter__traceTo : float3&;
                             var distance_meter__selectedPointIdx : int&;
                             distance_meter__points : Point3List)
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false
    let traceDir = transform[2]
    distance_meter__traceFrom = transform[3]

    var len = 4000f
    var norm : float3
    var matId = PHYSMAT_INVALID
    var riDesc = RendInstDesc()
    if traceray_normalized(distance_meter__traceFrom, traceDir, len, matId, norm, ETF_ALL, riDesc, -1)
      distance_meter__traceTo = distance_meter__traceFrom + traceDir * len
    else
      distance_meter__traceTo = float3(0., 0., 0.)

    distance_meter__selectedPointIdx = findClosestPointToCameraTrace(distance_meter__points, 0.0001, distance_meter__traceFrom, traceDir)

    return true


[es(tag=input, before=draw_distance_meter_es, REQUIRE=distanceMeterDebug)]
def distance_meter_input(evt : EventDaInputActionTriggered;
                         distance_meter__traceTo : float3;
                         distance_meter__selectedPointIdx : int;
                         var distance_meter__points : Point3List)
  if evt.action == get_action_handle("Human.Shoot", TYPEGRP_DIGITAL)
    if distance_meter__traceTo != float3(0., 0., 0.)
      if distance_meter__selectedPointIdx >= 0
        distance_meter__points |> erase(distance_meter__selectedPointIdx)
      else
        distance_meter__points |> push(distance_meter__traceTo)
  elif evt.action == get_action_handle("Human.Reload", TYPEGRP_DIGITAL)
    clear(distance_meter__points)


def draw_navmesh_line(startPoint : float3;
                      finishPoint : float3;
                      cameraPos : float3;
                      color : E3DCOLOR;
                      var distance : float&;
                      var midPointPosition : float3&)
  let extents = float3(0.5, FLT_MAX, 0.5)
  using(startPoint, finishPoint, extents) <| $(var req : FindRequest#)
    req.includeFlags |= int(PolyFlag POLYFLAG_JUMP)
    req.maxJumpUpHeight = FLT_MAX
    find_path(req, 1., 0.25) <| $(path)
      distance = 0.
      if length(path) > 0
        for j in range(1, length(path))
          draw_cached_debug_line(path[j - 1], path[j], color)
          draw_cached_debug_sphere(path[j], 0.001 * length(path[j] - cameraPos), color, 24)
          distance += length(path[j] - path[j - 1])
        draw_cached_debug_line(path[length(path) - 1], finishPoint, color)
        distance += length(finishPoint - path[length(path) - 1])
        midPointPosition = path[length(path) / 2]
      else
        distance = length(startPoint - finishPoint)
        draw_cached_debug_line(startPoint, finishPoint, color)
        midPointPosition = (startPoint + finishPoint) / 2.


[es(tag=render, no_order, REQUIRE=distanceMeterDebug)]
def draw_distance_meter_es(evt : UpdateStageInfoRenderDebug;
                           distance_meter__points : Point3List;
                           distance_meter__traceFrom : float3;
                           distance_meter__traceTo : float3;
                           distance_meter__selectedPointIdx : int;
                           distance_meter__navmeshMode : bool)
  var sum_distance = 0.
  let color = E3DCOLOR(0xFFFF0000)
  let selectedColor = E3DCOLOR(0xFF0000FF)
  let radiusMultiplier = 0.007

  begin_draw_cached_debug_lines(false, false, false)

  if distance_meter__traceTo != float3(0, 0, 0) && distance_meter__selectedPointIdx < 0
    draw_cached_debug_sphere(distance_meter__traceTo,
                             radiusMultiplier * length(distance_meter__traceTo - distance_meter__traceFrom),
                             color,
                             24)

  if length(distance_meter__points) <= 0
    end_draw_cached_debug_lines()
    return

  draw_cached_debug_sphere(distance_meter__points[0],
                           radiusMultiplier * length(distance_meter__points[0] - distance_meter__traceFrom),
                           distance_meter__selectedPointIdx == 0 ? selectedColor : color,
                           24)

  for i in range(1, length(distance_meter__points))
    var currentLineLength = 0.
    var pos = float3(0, 0, 0)
    draw_cached_debug_sphere(distance_meter__points[i],
                             radiusMultiplier * length(distance_meter__points[i] - distance_meter__traceFrom),
                             distance_meter__selectedPointIdx == i ? selectedColor : color,
                             24)

    if distance_meter__navmeshMode
      draw_navmesh_line(distance_meter__points[i - 1], distance_meter__points[i], distance_meter__traceFrom, color, currentLineLength, pos)
    else
      currentLineLength = length(distance_meter__points[i] - distance_meter__points[i - 1])
      draw_cached_debug_line(distance_meter__points[i - 1], distance_meter__points[i], color)
      pos = (distance_meter__points[i] + distance_meter__points[i - 1]) / 2.

    sum_distance += currentLineLength
    add_debug_text_mark(pos, format("%.2fm", currentLineLength), -1, 0., E3DCOLOR(0xFF000000))

  add_debug_text_mark(distance_meter__points[length(distance_meter__points) - 1],
                      format("sum distance = %.2fm", sum_distance),
                      -1, 0., E3DCOLOR(0xFF000000))

  end_draw_cached_debug_lines()
