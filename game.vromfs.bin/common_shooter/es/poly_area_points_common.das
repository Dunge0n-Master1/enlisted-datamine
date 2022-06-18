module poly_area_points_common shared
require ecs
require DagorSystem

struct PolygonAreaPoint
  id : string
  nextId : string
  pos : float2
  visited : bool

def find_next_point_index(nextId, points)
  return find_index_if(points) <| $(p) : bool { return p.id == nextId; }

def poly_area_create_on_load_es_impl(var polygon_area_points : ecs::Point2List; var points : array<PolygonAreaPoint>; area_id : string)
  let pointsCount = length(points)
  if (pointsCount < 3)
    logerr("area must have at least 3 points, area id {area_id}")
  resize(polygon_area_points, pointsCount)
  var curPointId = 0
  try
    for i in range(pointsCount)
      assert(!points[curPointId].visited || curPointId == 0)
      points[curPointId].visited = true
      polygon_area_points[i] = points[curPointId].pos
      curPointId = find_next_point_index(points[curPointId].nextId, points)
  recover
    logerr("Segments don't form a closed polygonal chain or loop has been detected in the area's polygon {area_id}")