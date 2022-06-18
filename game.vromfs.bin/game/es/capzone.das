require ecs
require pathfinder
require DagorSystem
require game.es.events
require enlisted.events_enlisted
require DagorMath
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
  for point in points_to_check
    if check_path(point, pos, 1.5, 0.5, 0.5)
      return true
  return false

def get_nearest_pos(zone_eid : EntityId; pos : float3; radius : float; points_to_check : array<float3>) : MaybePos
  var nearestPos = get_lower_navmesh_pos(pos, radius) <| $(p)
    return validate_pos_for_capzone(p, zone_eid, points_to_check)
  if nearestPos is invalid
    nearestPos = get_lower_navmesh_pos_in_radius(pos, radius) <| $(p)
      return validate_pos_for_capzone(p, zone_eid, points_to_check)
  return nearestPos

def init_nearest_pos(eid : EntityId; transform : float3x4; distance : float; points_to_check : array<float3>;
                     var capzone__hasNearestNavmeshPos : bool&; var capzone__nearestNavmeshPos : float3&)
  capzone__hasNearestNavmeshPos = false
  var pos = get_nearest_pos(eid, transform[3], min(0.6f, distance), points_to_check)
  if pos is invalid
    pos = get_nearest_pos(eid, transform[3], min(4f, distance), points_to_check)
  capzone__hasNearestNavmeshPos = pos is pos
  if capzone__hasNearestNavmeshPos
    capzone__nearestNavmeshPos = pos as pos
  else
    logerr("can't find nearest navmesh position for capzone {eid} <{getEntityTemplateName(eid)}> at {transform[3]}")
    capzone__hasNearestNavmeshPos = true
    capzone__nearestNavmeshPos = transform[3]
  sendEvent(eid, [[InitCapzoneRadius]])


[es(tag=server, on_event=EventLevelLoaded, after=poly_capzone_area_create_on_load_es)]
def capzone_init_all_nearest_navmesh_points(evt : Event)
  if (find_query() <| $ [es(REQUIRE=navmeshDisabler)] () => true)
    return
  var respbases : array<float3>
  get_respbases(respbases)
  query() <| $ [es] (eid : EntityId; transform : float3x4;
                     sphere_zone__radius : float = 0.0;
                     capzone__minHeight : float = 0.0;
                     capzone__maxHeight : float = 0.0;
                     var capzone__hasNearestNavmeshPos : bool&;
                     var capzone__nearestNavmeshPos : float3&)
    var distance = sphere_zone__radius > 0.0 ? sphere_zone__radius : (capzone__maxHeight - capzone__minHeight)
    if distance <= 0.0
      distance = 0.5 * min(length(transform[0]), length(transform[2]))
    init_nearest_pos(eid, transform, distance, respbases, capzone__hasNearestNavmeshPos, capzone__nearestNavmeshPos)

[es(tag=server)]
def init_sphere_capzone_radius(evt : InitCapzoneRadius; transform : float3x4; sphere_zone__radius : float;
                               capzone__hasNearestNavmeshPos : bool; capzone__nearestNavmeshPos : float3;
                               var capzone__minRadius : float&)
  capzone__minRadius = sphere_zone__radius
  if capzone__hasNearestNavmeshPos
    capzone__minRadius = max(0f, capzone__minRadius - length(transform[3].xz - capzone__nearestNavmeshPos.xz))

[es(tag=server)]
def init_box_capzone_radius(evt : InitCapzoneRadius; transform : float3x4;
                            capzone__hasNearestNavmeshPos : bool; capzone__nearestNavmeshPos : float3;
                            var capzone__minRadius : float&)
  capzone__minRadius = 0.5 * min(transform[0] |> length(), transform[2] |> length())
  if capzone__hasNearestNavmeshPos
    capzone__minRadius = max(0f, capzone__minRadius - length(transform[3].xz - capzone__nearestNavmeshPos.xz))
