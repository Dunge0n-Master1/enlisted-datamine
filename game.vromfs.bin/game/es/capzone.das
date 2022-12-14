require ecs
require pathfinder
require DagorSystem
require game.es.events
require enlisted.events_enlisted
require DagorMath
require DagorRandom
require math.base
require zones
require danetlibs.pathfinder.main.pathfinder_common


def get_respbases(var list : array<float3>; count : int = -1)
  var respawnsToFound = count
  find_query() <| $ [es(REQUIRE=respbase)] (transform : float3x4)
    list |> push(transform[3])
    respawnsToFound--
    return respawnsToFound == 0

def validate_pos_for_capzone(pos; zone_eid; points_to_check)
  if !is_point_in_capzone(pos, zone_eid, 1.0)
    return false
  let extents = float3(1.5, FLT_MAX, 1.5)
  for point in points_to_check
    if check_path(point, pos, extents, 0.5, 0.5)
      return true
  return false

def get_nearest_pos(zone_eid : EntityId; pos : float3; radius : float; points_to_check : array<float3>) : MaybePos
  var nearestPos = get_lower_navmesh_pos(pos, radius) <| $(p)
    return validate_pos_for_capzone(p, zone_eid, points_to_check)
  if nearestPos is invalid
    nearestPos = get_lower_navmesh_pos_in_radius(pos, radius) <| $(p)
      return validate_pos_for_capzone(p, zone_eid, points_to_check)
  return nearestPos

def init_nearest_pos(eid : EntityId;
                     transform : float3x4;
                     sphere_zone__radius : float;
                     capzone__approximateRadius : float;
                     points_to_check : array<float3>;
                     var capzone__hasNearestNavmeshPos : bool&;
                     var capzone__nearestNavmeshPos : float3&;
                     var capzone__insideNavmeshPositions : Point3List&;
                     var capzone__outsideNavmeshPositions : Point3List&;
                     capzone__maxNavPoints : int = 20)
  clear(capzone__insideNavmeshPositions)
  clear(capzone__outsideNavmeshPositions)

  capzone__hasNearestNavmeshPos = false
  let radius = sphere_zone__radius > 0.0 ? sphere_zone__radius : capzone__approximateRadius > 0.0 ? capzone__approximateRadius : 0.5 * min(length(transform[0]), length(transform[2]))
  var pos = get_nearest_pos(eid, transform[3], min(0.6f, radius), points_to_check)
  if pos is invalid
    pos = get_nearest_pos(eid, transform[3], min(4f, radius), points_to_check)
  capzone__hasNearestNavmeshPos = pos is pos
  if capzone__hasNearestNavmeshPos
    capzone__nearestNavmeshPos = pos as pos
  else
    logerr("can't find nearest navmesh position for capzone {eid} <{getEntityTemplateName(eid)}> at {transform[3]}")
    capzone__hasNearestNavmeshPos = true
    capzone__nearestNavmeshPos = transform[3]

  let projRadius = 1.5
  let distToPath = float3(0.5, FLT_MAX, 0.5)
  let stepSize = 0.5
  let pathSlop = 0.25

  for _i in range(capzone__maxNavPoints)
    let rndAngle     = rnd_float(0.0, TWOPI)
    let rndInRadius  = rnd_float(0.0, radius)
    let rndOutRadius = radius + rndInRadius

    var cosAngle = 0.
    var sinAngle = 0.

    sincos(rndAngle, sinAngle, cosAngle)

    let biasInPos  = float3(rndInRadius * cosAngle,
                            0.,
                            rndInRadius * sinAngle)

    let biasOutPos = float3(rndOutRadius * cosAngle,
                            0.,
                            rndOutRadius * sinAngle)

    var newInPos  = capzone__nearestNavmeshPos + biasInPos
    var newOutPos = capzone__nearestNavmeshPos + biasOutPos

    let projExtents = float3(projRadius, FLT_MAX, projRadius)

    if (project_to_nearest_navmesh_point_no_obstacles(newInPos, projExtents) &&
        find_path(capzone__nearestNavmeshPos, newInPos, distToPath, stepSize, pathSlop) == FindPathResult FPR_FULL)
      push(capzone__insideNavmeshPositions, newInPos)

    if (project_to_nearest_navmesh_point_no_obstacles(newOutPos, projExtents) &&
        find_path(capzone__nearestNavmeshPos, newOutPos, distToPath, stepSize, pathSlop) == FindPathResult FPR_FULL)
      push(capzone__outsideNavmeshPositions, newOutPos)

  if length(capzone__outsideNavmeshPositions) == 0
    push(capzone__outsideNavmeshPositions, capzone__nearestNavmeshPos)
  if length(capzone__insideNavmeshPositions) == 0
    push(capzone__insideNavmeshPositions, capzone__nearestNavmeshPos)

  sendEvent(eid, [[InitCapzoneRadius]])

[es(tag=server, REQUIRE_NOT=moveable_capzone, after=poly_capzone_area_calc)]
def capzone_init_nearest_navmesh_point(evt : EventEntityCreated;
                                       eid : EntityId;
                                       transform : float3x4;
                                       sphere_zone__radius : float = 0.0;
                                       capzone__approximateRadius : float = 0.0;
                                       var capzone__hasNearestNavmeshPos : bool&;
                                       var capzone__nearestNavmeshPos : float3&;
                                       var capzone__insideNavmeshPositions : Point3List&;
                                       var capzone__outsideNavmeshPositions : Point3List&)
  if pathfinder_is_loaded()
    var respbases : array<float3>
    get_respbases(respbases)
    init_nearest_pos(eid, transform, sphere_zone__radius, capzone__approximateRadius, respbases,
                     capzone__hasNearestNavmeshPos, capzone__nearestNavmeshPos,
                     capzone__insideNavmeshPositions, capzone__outsideNavmeshPositions)

[es(tag=server, on_event=EventLevelLoaded, after=poly_capzone_area_calc)]
def capzone_init_all_nearest_navmesh_points(evt : Event)
  if (find_query() <| $ [es(REQUIRE=navmeshDisabler)] () => true)
    return
  var respbases : array<float3>
  get_respbases(respbases)
  query() <| $ [es(REQUIRE_NOT=moveable_capzone)] (eid : EntityId;
                                                   transform : float3x4;
                                                   sphere_zone__radius : float = 0.0;
                                                   capzone__approximateRadius : float = 0.0;
                                                   var capzone__hasNearestNavmeshPos : bool&;
                                                   var capzone__nearestNavmeshPos : float3&;
                                                   var capzone__insideNavmeshPositions : Point3List&;
                                                   var capzone__outsideNavmeshPositions : Point3List&)
    init_nearest_pos(eid, transform, sphere_zone__radius, capzone__approximateRadius, respbases,
                     capzone__hasNearestNavmeshPos, capzone__nearestNavmeshPos,
                     capzone__insideNavmeshPositions, capzone__outsideNavmeshPositions)

[es(tag=server)]
def init_capzone_radius(evt : InitCapzoneRadius; transform : float3x4;
                        sphere_zone__radius : float = 0.0; capzone__approximateRadius : float = 0.0;
                        capzone__hasNearestNavmeshPos : bool; capzone__nearestNavmeshPos : float3;
                        var capzone__minRadius : float&)
  capzone__minRadius = sphere_zone__radius > 0.0 ? sphere_zone__radius : capzone__approximateRadius > 0.0 ? capzone__approximateRadius : 0.5 * min(transform[0] |> length(), transform[2] |> length())
  if capzone__hasNearestNavmeshPos
    capzone__minRadius = max(0f, capzone__minRadius - length(transform[3].xz - capzone__nearestNavmeshPos.xz))
