require ecs
require app
require DagorSystem
require common_shooter.es.poly_area_points_common
require game.es.events


def get_battle_area_id_points(areaId : string; delete_points : bool)
  var points : array<PolygonAreaPoint>
  query() <| $ [es] (eid : EntityId;
                     battle_area_polygon_point__nextId : string;
                     battle_area_polygon_point__id : string;
                     battle_area_polygon_point__forBattleAreaId : string;
                     transform : float3x4)
    if battle_area_polygon_point__forBattleAreaId == areaId
      push(points, [[PolygonAreaPoint id=battle_area_polygon_point__id, nextId=battle_area_polygon_point__nextId, pos=transform[3]]])
      if delete_points
        destroyEntity(eid)
  return <- points


[es(tag=server, on_event=(EventLevelLoaded, CmdInitPolyBattleAreas), REQUIRE=battle_area)]
def poly_battle_area_init_points(evt : Event;
                                 battleAreaId : string;
                                 var battleAreaPoints : Point2List;
                                 var poly_area__points : Point3List)
  // temp disable compact system for sandbox until we add better support to the poly area editor
  let isSandbox = get_app_offline_mode()
  let unorderedAreaPoints <- get_battle_area_id_points(battleAreaId, !isSandbox)

  if length(unorderedAreaPoints) != 0
    if length(poly_area__points) != 0 && !isSandbox
      logerr("Battle area {battleAreaId} uses both compact and non compact poly points. Using compact form only.")
    else
      poly_area__points |> poly_area_get_points_ordered(unorderedAreaPoints, battleAreaId)

  battleAreaPoints |> resize(length(poly_area__points))
  for bp, p in battleAreaPoints, poly_area__points
    bp = p.xz

[es(tag=server, on_event=EventLevelLoaded)]
def poly_battle_area_compact_navmesh_verefication_on_load_es(evt : Event; level__fixedBattleAreas : bool)
  if !level__fixedBattleAreas || get_app_offline_mode()
    return
  find_query() <| $ [es] (battle_area_polygon_point__forBattleAreaId : string)
    logerr("This level is using fixed human battle areas, point of {battle_area_polygon_point__forBattleAreaId} should be created before level entity in {get_current_scene()}")
    return true

[es(tag=server, on_event=EventLevelLoaded, REQUIRE=battle_area, before=poly_battle_area_init_points)]
def poly_battle_area_navmesh_verefication_on_load_es(evt : Event; eid : EntityId; battleAreaPoints : ecs::Point2List; battleAreaId : string)
  if !get_app_offline_mode()
    return
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