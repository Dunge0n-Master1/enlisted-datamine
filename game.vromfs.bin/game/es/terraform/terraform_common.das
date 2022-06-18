module terraform_common shared
require ecs
require Dacoll
require DagorMath
require PhysMat
require Grid
require GridCollision
require terraform

let TRACE_HEIGHT = 0.5

def has_ri_in_radius(pos : float3; radius : float; height : float; trace_handle : TraceMeshFaces?)
  var isHit = false
  var queryOut = ShapeQueryOutput()

  let halfHeight = height * 0.5
  let traceStart = pos + float3(0.0, halfHeight, 0.0)
  let traceEnd = pos - float3(0.0, halfHeight, 0.0)
  sphere_query_ri(traceStart, traceEnd, radius, queryOut, -1, trace_handle) <| $(desc : array<RendInstDesc>#)
    isHit = length(desc) != 0

  return isHit

def has_frt_ri_in_radius(pos : float3; radius : float; trace_height : float)
  let traceLen = trace_height
  let traceHeightOffset = float3(0.0, traceLen, 0.0) * 0.5

  for offset in [[float2 float2(0, 0); float2(-1, -1); float2(1, -1); float2(-1, 1); float2(1, 1)]]
    var len = traceLen
    let normalizedOffset = normalize(float3(offset.x, 0.0, offset.y))
    let traceStartPos = pos + traceHeightOffset + normalizedOffset * radius
    if tracedown_normalized(traceStartPos, len, ETF_FRT)
      return true

  return false

def can_terraform_at_pos(terraform : TerraformComponent; pos : float3; radius : float; trace_handle : TraceMeshFaces?)
  let posXZ = pos.xz
  let origHeight = terraform_getHmapHeightOrigValAtPos(terraform, posXZ)
  let posWithOrigHeight = float3(pos.x, origHeight, pos.z)

  if has_frt_ri_in_radius(pos, radius, TRACE_HEIGHT)
    return false

  if has_ri_in_radius(posWithOrigHeight, radius, TRACE_HEIGHT, trace_handle)
    return false

  var isTerraformingBlocked = false
  find_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], BBox3(posWithOrigHeight, radius * 2.0), GridEntCheck POS) <| $(eid : EntityId)
    isTerraformingBlocked ||= has(eid, "blockTerraform")
    return isTerraformingBlocked

  return !isTerraformingBlocked