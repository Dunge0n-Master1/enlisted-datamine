module terraform_common shared
require ecs
require ecs.safe
require ecs.enum_macro
require Dacoll
require DagorMath
require PhysMat
require Grid
require GridCollision
require terraform

[export_enum]
enum CanTerraformCheckResult : int
  Successful
  OutOfHeightMap
  DisallowedMaterials
  NearByObjects

let TRACE_HEIGHT = 0.5

def check_material_valid_to_dig(matId : int;
                                [[shared_comp]] dig_tool__allowedMaterials : Object)
  return matId >= 0 && dig_tool__allowedMaterials[get_material_name(get_material(matId))] ?? false

def check_dig_materials_at_radius(pos : float3;
                                  check_radius : float;
                                  [[shared_comp]] dig_tool__allowedMaterials : Object;
                                  var matId : int&)
  let forwardDir = float2(check_radius, 0.)
  let rightDir = float2(0., check_radius)
  let digPos = pos.xz;

  matId = dacoll_get_lmesh_mat_id_at_point(digPos)
  if !check_material_valid_to_dig(matId, dig_tool__allowedMaterials)
    return false

  let checkPositions = [[float2[4]
                         digPos + forwardDir;
                         digPos - forwardDir;
                         digPos + rightDir;
                         digPos - rightDir]]
  for p in checkPositions
    if !check_material_valid_to_dig(dacoll_get_lmesh_mat_id_at_point(p), dig_tool__allowedMaterials)
      return false
  return true

def has_query_ri_in_radius(pos : float3; radius : float; height : float; trace_handle : TraceMeshFaces?)
  var isHit = false
  var queryOut = ShapeQueryOutput()

  let halfHeight = height * 0.5
  let traceStart = pos + float3(0.0, halfHeight, 0.0)
  let traceEnd = pos - float3(0.0, halfHeight, 0.0)
  sphere_query_ri(traceStart, traceEnd, radius, queryOut, -1, trace_handle) <| $(desc : array<RendInstDesc>#)
    isHit = length(desc) != 0

  return isHit

def has_trace_ri_in_radius(pos : float3; radius : float; trace_height : float)
  let traceLen = trace_height
  let traceHeightOffset = float3(0.0, traceLen, 0.0) * 0.5

  for offset in [[float2 float2(0, 0); float2(-1, -1); float2(1, -1); float2(-1, 1); float2(1, 1)]]
    var len = traceLen
    let normalizedOffset = normalize(float3(offset.x, 0.0, offset.y))
    let traceStartPos = pos + traceHeightOffset + normalizedOffset * radius
    if tracedown_normalized(traceStartPos, len, ETF_FRT | ETF_RI)
      return true

  return false

def can_terraform_at_pos(terraform : TerraformComponent;
                         pos : float3;
                         radius : float;
                         trace_handle : TraceMeshFaces?;
                         [[shared_comp]] dig_tool__allowedMaterials : Object;
                         var matId : int&)
  let posXZ = pos.xz
  if !is_valid_heightmap_pos(posXZ)
    return CanTerraformCheckResult OutOfHeightMap

  if !check_dig_materials_at_radius(pos, radius, dig_tool__allowedMaterials, matId)
    return CanTerraformCheckResult DisallowedMaterials

  let origHeight = terraform_getHmapHeightOrigValAtPos(terraform, posXZ)
  let posWithOrigHeight = float3(pos.x, origHeight, pos.z)

  if has_trace_ri_in_radius(pos, radius, TRACE_HEIGHT)
    return CanTerraformCheckResult NearByObjects

  if has_query_ri_in_radius(posWithOrigHeight, radius, TRACE_HEIGHT, trace_handle)
    return CanTerraformCheckResult NearByObjects

  var isTerraformingBlocked = false
  find_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], BBox3(posWithOrigHeight, radius), GridEntCheck BOUNDING) <| $(eid : EntityId)
    isTerraformingBlocked ||= has(eid, "blockTerraform")
    return isTerraformingBlocked

  return isTerraformingBlocked ? CanTerraformCheckResult NearByObjects : CanTerraformCheckResult Successful

def clean_loot_in_radius(pos : float3; radius : float)
  let sphere = BSphere3(pos, radius)
  for_each_entity_in_grid(ecs_hash("loot"), sphere, GridEntCheck POS) <| $ [unused_argument(loot_pos)] (loot_eid : EntityId; loot_pos : float3)
    destroyEntity(loot_eid)
