module scenery_rendinsts_common shared
require ecs
require RendInst
require RiDestr
require Dacoll
require DagorMath

def is_nearly_same_float3(a, b, eps)
  if abs(a.x - b.x) > eps
    return false
  if abs(a.y - b.y) > eps
    return false
  if abs(a.z - b.z) > eps
    return false
  return true

def is_nearly_same_ri_tm(a, b)
  if !is_nearly_same_float3(a[0], b[0], 0.001)
    return false
  if !is_nearly_same_float3(a[1], b[1], 0.001)
    return false
  if !is_nearly_same_float3(a[2], b[2], 0.001)
    return false
  if !is_nearly_same_float3(a[3], b[3], 0.025)
    return false
  return true

def remove_rendinst(tm, name) : bool
  var result = false
  let poolsCount = rendinst_getRiGenExtraResCount()
  for pool_id in range(poolsCount)
    let riName = riex_getRIGenExtraName(uint(pool_id))
    if riName != name
      continue
    let bsph = getRIGenExtraBSphereByTM(uint(pool_id), tm)
    let pt1 = float3(bsph.x - bsph.w, bsph.y - bsph.w, bsph.z - bsph.w)
    let pt2 = float3(bsph.x + bsph.w, bsph.y + bsph.w, bsph.z + bsph.w)
    var bbox : bbox3f
    bbox.bmin = float4(pt1, 0.f)
    bbox.bmax = float4(pt2, 0.f)
    getRiGenExtraInstances(pool_id, bbox) <| $(handles : array<riex_handle_t>#)
      for handle in handles
        if !riex_isRiGenExtraValid(handle)
          continue
        if find_ri_extra_eid(handle) != INVALID_ENTITY_ID
          continue
        var riTm : float3x4
        get_rigen_extra_matrix(handle, riTm)
        if is_nearly_same_ri_tm(tm, riTm)
          var out_desc = RendInstDesc()
          destroyRendinst(RendInstDesc(handle), out_desc)
          rendinst_delRIGenExtra(out_desc.riExtraHandle)
          result = true
          return
    break
  return result
