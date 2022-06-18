module train_common shared


require ecs
require daslib.algorithm


[event(unicast)]
struct DebugReinitTrain {}


def compare_points(a, b : float3)
  let signAx = sign(a.x)
  let signBx = sign(b.x)
  let signA = signAx != 0. ? signAx : sign(a.z)
  let signB = signBx != 0. ? signBx : sign(b.z)
  return signA * length_sq(a) > signB * length_sq(b)


def project_on_railroad(p : float3)
  var projectedPoint = p

  find_query() <| $ [es] (railroad__points : Point3List)
    let pointNo = railroad__points |> lower_bound(p) <| $(a, b)
      return compare_points(a, b)

    let pointsCount = length(railroad__points)

    if pointNo >= 1 && pointNo < pointsCount
      let segmentFrom = railroad__points[pointNo - 1]
      let segmentTo   = railroad__points[pointNo]
      let segmentDir  = normalize(segmentTo - segmentFrom)
      projectedPoint  = segmentFrom + dot(p - segmentFrom, segmentDir) * segmentDir
    elif pointNo <= 0
      projectedPoint = railroad__points[0]
    elif pointNo >= pointsCount
      projectedPoint = railroad__points[pointsCount - 1]

    return true

  return projectedPoint
