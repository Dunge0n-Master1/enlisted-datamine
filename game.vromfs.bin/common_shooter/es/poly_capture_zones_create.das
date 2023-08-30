require ecs
require app
require DagorSystem
require math.base
require common_shooter.es.poly_area_points_common
require game.es.events

def get_capzone_area_id_points(areaId : string; delete_points : bool)
  var points : array<PolygonAreaPoint>
  query() <| $ [es] (eid : EntityId;
                     capzone_area_polygon_point__nextId : string;
                     capzone_area_polygon_point__id : string;
                     capzone_area_polygon_point__forcapzone_areaId : string;
                     transform : float3x4)
    if capzone_area_polygon_point__forcapzone_areaId == areaId
      push(points, [[PolygonAreaPoint id=capzone_area_polygon_point__id, nextId=capzone_area_polygon_point__nextId, pos=transform[3]]])
      if delete_points
        destroyEntity(eid)
  return <- points

def init_capzone_area_tm_height_by_points(var capzone_tm : float3x4; var min_height : float&; var max_height : float&; points : Point3List)
  var heightInited = false
  capzone_tm = IDENT_TM
  for pos in points
    capzone_tm[3] += pos
    let pointHeight = pos.y
    if !heightInited
      min_height = pointHeight
      max_height = pointHeight
      heightInited = true
      continue
    if pointHeight < min_height
      min_height = pointHeight
    if pointHeight > max_height
      max_height = pointHeight
  let capzonesCount = length(points)
  if capzonesCount > 0
    capzone_tm[3] /= float(capzonesCount)

[es(tag=server, on_appear, on_event=(EventLevelLoaded, CmdInitPolyCapzoneAreas), after=poly_capzone_area_create_init)]
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

[es(tag=server, on_event=(EventLevelLoaded, CmdInitPolyCapzoneAreas), REQUIRE=capzone)]
def poly_capzone_area_create_init(evt : Event;
                                  capzone__areaId : string;
                                  var transform : float3x4;
                                  var capzone__maxHeight : float&;
                                  var capzone__minHeight : float&;
                                  var capzone__areaPoints : Point2List;
                                  var poly_area__points : Point3List)
  let isSandbox = get_app_offline_mode()
  let unorderedAreaPoints <- get_capzone_area_id_points(capzone__areaId, !isSandbox)

  if length(unorderedAreaPoints) != 0
    if length(poly_area__points) != 0 && !isSandbox
      logerr("Poly capzone {capzone__areaId} uses both compact and non compact poly points. Using compact form only.")
    else
      poly_area__points |> poly_area_get_points_ordered(unorderedAreaPoints, capzone__areaId)

  init_capzone_area_tm_height_by_points(transform, capzone__minHeight, capzone__maxHeight, poly_area__points)

  capzone__areaPoints |> resize(length(poly_area__points))
  for cp, p in capzone__areaPoints, poly_area__points
    cp = p.xz
