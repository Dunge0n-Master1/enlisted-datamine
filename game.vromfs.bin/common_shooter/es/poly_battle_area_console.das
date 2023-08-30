options no_aot
require ecs
require game.es.events
require DagorMath
require DagorConsole
require DagorSystem
require DagorDebug3D

[console_cmd(name="battleAreas.reinit_active_poly_areas")]
def reinit_active_poly_areas()
  broadcastEvent([[CmdInitPolyBattleAreas]])

[console_cmd(name="battleAreas.draw_active_poly_areas")]
def draw_active_poly_areas(draw_info : bool = true)
  ecs::query() <| $ [es(REQUIRE=battleAreaPoints)] (eid : EntityId; active : bool; battleAreaId : string)
    if !draw_info
      removeSubTemplate(eid, "poly_battle_area_draw_debug")
      return
    if active
      var height = 0.f
      query() <| $ [es] (battle_area_polygon_point__forBattleAreaId : string; transform : float3x4)
        let pointHeight = transform[3][1]
        if (battle_area_polygon_point__forBattleAreaId == battleAreaId) && (pointHeight > height)
          height = pointHeight
      addSubTemplate(eid, "poly_battle_area_draw_debug") <| $(var init)
        set(init, "battle_area_polygon_point__drawOnHeight", height)
        set(init, "battle_area_polygon_point__drawDebug", draw_info)

def point2_to_point3_height(inPoint, height)
  return float3(inPoint.x, height, inPoint.y)

def get_team_color(team)
  if team == 1
    return E3DCOLOR(0xFF2222DD)
  if team == 2
    return E3DCOLOR(0xFFDD2222)
  return E3DCOLOR(0xFFFFFFFF)

[es(tag=render, no_order)]
def poly_areas_draw_lines_es(evt : UpdateStageInfoRenderDebug;
                             battle_area__team : int;
                             battleAreaPoints : ecs::Point2List;
                             battle_area_polygon_point__drawDebug : bool;
                             battle_area_polygon_point__drawOnHeight : float;
                             battle_area_polygon_point__additionalHeight : float)
  if (!battle_area_polygon_point__drawDebug || length(battleAreaPoints) == 0)
    return
  let height = battle_area_polygon_point__drawOnHeight + battle_area_polygon_point__additionalHeight
  let color = get_team_color(battle_area__team)
  for i in iter_range(battleAreaPoints)
    let pointStart = point2_to_point3_height(battleAreaPoints[i], height)
    let pointEnd = point2_to_point3_height(battleAreaPoints[(i + 1) % length(battleAreaPoints)], height)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)


[es(tag=render, no_order)]
def poly_areas_draw_points_es(evt : UpdateStageInfoRenderDebug;
                              battle_area_polygon_point__drawDebug : bool;
                              battle_area__team : int;
                              battleAreaId : string)

  if !battle_area_polygon_point__drawDebug
    return
  let color = get_team_color(battle_area__team)
  query() <| $ [es] (battle_area_polygon_point__nextId : string;
                     battle_area_polygon_point__id : string;
                     battle_area_polygon_point__forBattleAreaId : string;
                     transform : float3x4)
    if battle_area_polygon_point__forBattleAreaId == battleAreaId
      add_debug_text_mark(transform[3], "{battleAreaId}: {battle_area_polygon_point__id} -> {battle_area_polygon_point__nextId}",
                          -1, 0., color)

[es(tag=server, on_event=CmdInitPolyBattleAreas, after=poly_battle_area_init_points, REQUIRE=battle_area_polygon_point__drawDebug)]
def poly_battle_area_check_points_orientation_es(evt : Event; battleAreaPoints : ecs::Point2List; battleAreaId : string)
  var area = 0.f
  let numOfPoints = length(battleAreaPoints)
  for i in range(0, numOfPoints)
    let pointId = (i + 1) % numOfPoints
    let point1 = battleAreaPoints[i]
    let point2 = battleAreaPoints[pointId]
    area += (point1.x - point2.x) * (point1.y + point2.y);
  area /= 2.f
  if area < 0.0
    logerr("Points should be counterclockwise. Error in {battleAreaId}")