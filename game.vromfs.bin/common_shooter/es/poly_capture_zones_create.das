require ecs
require app
require math.base
require common_shooter.es.poly_area_points_common

def get_capzone_area_id_points(areaId : string)
  var points : array<PolygonAreaPoint>
  query() <| $ [es] (capzone_area_polygon_point__nextId : string; capzone_area_polygon_point__id : string; capzone_area_polygon_point__forcapzone_areaId : string; transform : float3x4)
    if capzone_area_polygon_point__forcapzone_areaId == areaId
      push(points, [[PolygonAreaPoint id=capzone_area_polygon_point__id, nextId=capzone_area_polygon_point__nextId, pos=transform[3].xz]])
  return <- points

def init_capzone_area_tm_height_by_points(var capzone_tm : float3x4; var min_height : float&; var max_height : float&; areaId : string)
  var heightInited = false
  capzone_tm = IDENT_TM
  var capzonesCount = 0
  query() <| $ [es] (capzone_area_polygon_point__forcapzone_areaId : string; transform : float3x4)
    if capzone_area_polygon_point__forcapzone_areaId == areaId
      capzonesCount++
      let pos = transform[3]
      capzone_tm[3] += pos
      let pointHeight = pos.y
      if !heightInited
        min_height = pointHeight
        max_height = pointHeight
        heightInited = true
        return
      if pointHeight < min_height
        min_height = pointHeight
      if pointHeight > max_height
        max_height = pointHeight
  if capzonesCount > 0
    capzone_tm[3] /= float(capzonesCount)

[es(tag=server, on_appear, on_event=(EventLevelLoaded, CmdInitPolyCapzoneAreas), after=(poly_capzone_area_create_on_load_es, poly_capzone_area_create_on_reinit_es))]
def poly_capzone_area_calc(evt : Event;
                           transform : float3x4;
                           capzone__areaPoints : ecs::Point2List;
                           var capzone__approximateRadius : float&)
  let pointsCount = length(capzone__areaPoints)
  if pointsCount == 0
    return
  let pos2d = transform[3].xz
  for i in range(pointsCount)
    let distance = length_sq(capzone__areaPoints[i] - pos2d)
    if capzone__approximateRadius < distance
      capzone__approximateRadius = distance

  if capzone__approximateRadius > 0.0
    capzone__approximateRadius = sqrt(capzone__approximateRadius)

[es(tag=server, on_event=EventLevelLoaded, REQUIRE=capzone)]
def poly_capzone_area_create_on_load_es(evt : Event;
                                        capzone__areaId : string;
                                        var transform : float3x4;
                                        var capzone__maxHeight : float&;
                                        var capzone__minHeight : float&;
                                        var capzone__areaPoints : ecs::Point2List)
  var areaPoints <- get_capzone_area_id_points(capzone__areaId)
  init_capzone_area_tm_height_by_points(transform, capzone__minHeight, capzone__maxHeight, capzone__areaId)
  poly_area_create_on_load_es_impl(capzone__areaPoints, areaPoints, capzone__areaId)

[es(tag=server, on_event=CmdInitPolyCapzoneAreas, REQUIRE=capzone)]
def poly_capzone_area_create_on_reinit_es(evt : Event;
                                          capzone__areaId : string;
                                          var transform : float3x4;
                                          var capzone__maxHeight : float&;
                                          var capzone__minHeight : float&;
                                          var capzone__areaPoints : ecs::Point2List)
  var areaPoints <- get_capzone_area_id_points(capzone__areaId)
  init_capzone_area_tm_height_by_points(transform, capzone__minHeight, capzone__maxHeight, capzone__areaId)
  poly_area_create_on_load_es_impl(capzone__areaPoints, areaPoints, capzone__areaId)