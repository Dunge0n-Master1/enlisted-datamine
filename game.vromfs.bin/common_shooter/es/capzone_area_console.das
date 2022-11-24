options no_aot
require ecs
require common_shooter.events_common_shooter
require DagorMath
require DagorConsole
require DagorSystem
require DagorDebug3D

[console_cmd(name="capzone.reinit_active_poly_areas")]
def capzone_reinit_active_poly_areas()
  ecs::query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; active : bool)
    if active
      sendEvent(eid, [[CmdInitPolyCapzoneAreas]])

[console_cmd(name="capzone.draw_active_poly_areas")]
def capzone_draw_active_poly_areas(draw_info : bool = true)
  ecs::query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; active : bool)
    if !draw_info
      removeSubTemplate(eid, "poly_capzone_area_draw_debug")
      return
    if active
      addSubTemplate(eid, "poly_capzone_area_draw_debug") <| $(var init)
        set(init, "capzone_area_polygon_point__drawDebug", draw_info)

def point2_to_point3_height(inPoint, height)
  return float3(inPoint.x, height, inPoint.y)

def get_capzone_debug_color()
  return E3DCOLOR(0xFF00FF00)

[es(tag=render, no_order)]
def capzone_poly_areas_draw_lines_es(evt : UpdateStageInfoRenderDebug;
                                     capzone__areaPoints : ecs::Point2List;
                                     capzone__maxHeight : float&;
                                     capzone__minHeight : float&;
                                     capzone_area_polygon_point__drawDebug : bool)
  if (!capzone_area_polygon_point__drawDebug || length(capzone__areaPoints) == 0)
    return
  let color = get_capzone_debug_color()
  for i in iter_range(capzone__areaPoints)
    let nextPointId = (i + 1) % length(capzone__areaPoints)
    //line 1 (vertical)
    var pointStart = point2_to_point3_height(capzone__areaPoints[i], capzone__minHeight)
    var pointEnd = point2_to_point3_height(capzone__areaPoints[i], capzone__maxHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 2 (diag0)
    pointStart = point2_to_point3_height(capzone__areaPoints[i], capzone__minHeight)
    pointEnd = point2_to_point3_height(capzone__areaPoints[nextPointId], capzone__maxHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 3 (diag1)
    pointStart = point2_to_point3_height(capzone__areaPoints[i], capzone__maxHeight)
    pointEnd = point2_to_point3_height(capzone__areaPoints[nextPointId], capzone__minHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 4 (horizontal0)
    pointStart = point2_to_point3_height(capzone__areaPoints[i], capzone__minHeight)
    pointEnd = point2_to_point3_height(capzone__areaPoints[nextPointId], capzone__minHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 4 (horizontal1)
    pointStart = point2_to_point3_height(capzone__areaPoints[i], capzone__maxHeight)
    pointEnd = point2_to_point3_height(capzone__areaPoints[nextPointId], capzone__maxHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)


[es(tag=render, no_order)]
def capzone_poly_areas_draw_points_es(evt : UpdateStageInfoRenderDebug;
                                      capzone_area_polygon_point__drawDebug : bool;
                                      capzone__areaId : string)
  if !capzone_area_polygon_point__drawDebug
    return
  let color = get_capzone_debug_color()
  query() <| $ [es] (capzone_area_polygon_point__nextId : string;
                     capzone_area_polygon_point__id : string;
                     capzone_area_polygon_point__forcapzone_areaId : string;
                     transform : float3x4)
    if capzone_area_polygon_point__forcapzone_areaId == capzone__areaId
      add_debug_text_mark(transform[3], "{capzone__areaId}: {capzone_area_polygon_point__id} -> {capzone_area_polygon_point__nextId}",
                          -1, 0., color)

[es(tag=(server, dev), on_event=CmdInitPolyCapzoneAreas, after=poly_capzone_area_create_on_load_es, REQUIRE=capzone_area_polygon_point__drawDebug)]
def poly_capzone_area_check_points_orientation_es(evt : Event;
                                                  capzone__areaPoints : ecs::Point2List;
                                                  capzone__areaId : string)
  var area = 0.f
  let numOfPoints = length(capzone__areaPoints)
  for i in range(0, numOfPoints)
    let pointId = (i + 1) % numOfPoints
    let point1 = capzone__areaPoints[i]
    let point2 = capzone__areaPoints[pointId]
    area += (point1.x - point2.x) * (point1.y + point2.y);
  area /= 2.f
  if area < 0.0
    logerr("Points should be counterclockwise. Error in {capzone__areaId}")