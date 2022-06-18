require ecs
require app
require DagorSystem
require common_shooter.es.poly_area_points_common

def get_battle_area_id_points(areaId : string)
  var points : array<PolygonAreaPoint>
  query() <| $ [es] (battle_area_polygon_point__nextId : string; battle_area_polygon_point__id : string; battle_area_polygon_point__forBattleAreaId : string; transform : float3x4)
    if battle_area_polygon_point__forBattleAreaId == areaId
      push(points, [[PolygonAreaPoint id=battle_area_polygon_point__id, nextId=battle_area_polygon_point__nextId, pos=transform[3].xz]])
  return <- points

[es(tag=server, on_event=EventLevelLoaded, REQUIRE=battle_area)]
def poly_battle_area_create_on_load_es(evt : Event; var battleAreaPoints : ecs::Point2List; battleAreaId : string)
  var areaPoints <- get_battle_area_id_points(battleAreaId)
  poly_area_create_on_load_es_impl(battleAreaPoints, areaPoints, battleAreaId)

[es(tag=server, on_event=CmdInitPolyBattleAreas, REQUIRE=battle_area)]
def poly_battle_area_create_on_reinit_es(evt : Event; var battleAreaPoints : ecs::Point2List; battleAreaId : string)
  var areaPoints <- get_battle_area_id_points(battleAreaId)
  poly_area_create_on_load_es_impl(battleAreaPoints, areaPoints, battleAreaId)

[es(tag=server, on_event=EventLevelLoaded, REQUIRE=battle_area)]
def poly_battle_area_navmesh_verefication_on_load_es(evt : Event; eid : EntityId; battleAreaPoints : ecs::Point2List; battleAreaId : string)
  var pointsCount = 0
  query() <| $ [es] (battle_area_polygon_point__forBattleAreaId : string)
    if battle_area_polygon_point__forBattleAreaId == battleAreaId
      pointsCount++
  find_query() <| $ [es] (level__fixedBattleAreas : bool; level__navAreas : EidList)
    if level__fixedBattleAreas
      for navAreaEid in level__navAreas
        if navAreaEid == eid
          if (length(battleAreaPoints) != pointsCount)
            logerr("This level is using fixed human battle areas, point of {battleAreaId} should be created before level entity in {get_current_scene()}")
          return true;
    return false;
