module fortification_action_common shared

require ecs
require math.base
require Dacoll
require DagorMath
require DagorMathUtils


def validate_fortification_action_object_pos(object_pos : float3;
                                             trace_from : float3;
                                             eps : float = 0.1)
  let traceDir = object_pos - trace_from
  let dist = length(traceDir)
  let traceDirNormilised = traceDir * safeinv(dist)
  var norm : float3
  var validDist = max(0.f, dist - eps)
  return !traceray_normalized(trace_from, traceDirNormilised, validDist, norm, ETF_ALL)


def test_segment_sphere_intersection_nonblocking(p0 : float3;
                                                 p1 : float3;
                                                 sphere_center : float3;
                                                 squared_sphere_radius : float)
  let oc = sphere_center - p0

  let l2oc = dot(oc, oc)
  var rsqr = squared_sphere_radius
  if (rsqr > l2oc) // If inside shrink radius to 2/3 distance to center to keep control even close to center of sphere
    rsqr = l2oc * 0.45

  let dir = p1 - p0
  let tca = dot(oc, dir)
  if tca <= 0.0
    return false // Points away.

  let dir2 = dot(dir, dir)
  let tca2 = (tca * tca) / dir2
  let l2hc = rsqr - l2oc + tca2
  if l2hc < 0.0
    return false // Misses the sphere.

  if tca2 + l2hc - 2.0 * sqrt(tca2 * l2hc) > dir2
    return false // Segment ends.

  return true


def find_fortification_object_impl(eid : EntityId;
                                   is_engineer : bool;
                                   center : float3;
                                   center_offset : float3;
                                   radius : float;
                                   trace_from : float3;
                                   trace_to : float3;
                                   trace_max_len : float)
  let pos = center + center_offset
  if (length_sq(trace_from - pos) > square(trace_max_len))
    return INVALID_ENTITY_ID
  let onlyForEngineer = has(eid, "onlyForEngineer")
  var isPreviewFound  = !onlyForEngineer || is_engineer
  if isPreviewFound
    let isOnLineOfSight = test_segment_sphere_intersection_nonblocking(trace_from, trace_to, pos, square(radius))
    isPreviewFound &&= isOnLineOfSight
  return isPreviewFound ? eid : INVALID_ENTITY_ID
