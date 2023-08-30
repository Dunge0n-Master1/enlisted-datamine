module poly_area_points_common shared
require ecs
require DagorSystem

struct PolygonAreaPoint
  id : string
  nextId : string
  pos : float3

def find_next_point_index(nextId, points)
  return find_index_if(points) <| $(p) : bool { return p.id == nextId; }

def poly_area_get_points_ordered(var ordered_points : Point3List; points : array<PolygonAreaPoint>; area_id : string)
  let pointsCount = length(points)
  if (pointsCount < 3)
    logerr("area must have at least 3 points, area id {area_id}")

  var visistedPoints : array<bool>
  resize(visistedPoints, pointsCount)
  resize(ordered_points, pointsCount)

  var curPointId = 0
  try
    for i in range(pointsCount)
      assert(!visistedPoints[curPointId] || curPointId == 0)
      visistedPoints[curPointId] = true
      ordered_points[i] = points[curPointId].pos
      curPointId = find_next_point_index(points[curPointId].nextId, points)
  recover
    logerr("Segments don't form a closed polygonal chain or loop has been detected in the area's polygon {area_id}")
