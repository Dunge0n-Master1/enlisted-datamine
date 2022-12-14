require ecs
require game.es.events
require enlisted.game.es.fortifications_build_common
require DagorMath
require CollRes

def find_building(tm, box; base_collres : CollisionResource)
  var res = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=buildTypeId)] (eid : EntityId;
                                               transform : float3x4;
                                               ri_extra__bboxMin : float3;
                                               ri_extra__bboxMax : float3;
                                               previewCollres : CollisionResource const?;
                                               ri_extra__name : das_string const?)
    var objectFound = check_bbox3_intersection(box, tm, BBox3(ri_extra__bboxMin, ri_extra__bboxMax), transform)
    let buildingCollres = get_building_collres(previewCollres, ri_extra__name)
    if objectFound && buildingCollres != null
      var intersectPoint : float3
      objectFound = test_collres_intersection(base_collres, tm, *buildingCollres, transform, intersectPoint, intersectPoint, true)
    if objectFound
      res = eid
    return objectFound
  return res


[es(tag=server, no_order)]
def destroy_building_on_collision(info : UpdateStageInfoAct;
                                  transform : float3x4;
                                  collres : CollisionResource;
                                  destroy_buildings_collision__updateInterval : float;
                                  var destroy_buildings_collision__nextUpdateTime : float&)
  if info.curTime < destroy_buildings_collision__nextUpdateTime
    return
  destroy_buildings_collision__nextUpdateTime = info.curTime + destroy_buildings_collision__updateInterval
  destroyEntity(find_building(transform, BBox3(collres.vFullBBox), collres))