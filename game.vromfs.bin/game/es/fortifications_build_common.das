module fortifications_build_common shared
require game.utils.team
require GridCollision
require EnlistedWeapon
require DagorSystem
require DagorMath
require Grid
require RendInst
require CollRes
require AnimV20
require GeomNodeTree
require Dacoll
require math.base
require ecs
require zones

def change_building_limits(playerEid, buildTypeId, count)
  ecs::query(playerEid) <| $ [es] (var availableBuildings : IntList)
    availableBuildings[buildTypeId] += count

def get_engineer_building_speed_mul(human_weap__gunEids : ecs::EidList const)
  var buildingSpeedMul = 1.0
  for weapEid in human_weap__gunEids
    if has(weapEid, "engineerBuildingSpeedMul")
      buildingSpeedMul = get_float(weapEid, "engineerBuildingSpeedMul") ?? 1.0
      break
  return buildingSpeedMul

def get_building_collres(base_collres, riextra_name)
  if base_collres != null
    return base_collres
  if riextra_name != null
    let resName = string(deref(riextra_name))
    let resIndex = get_rigen_extra_res_idx(resName)
    return get_rigen_extra_coll_res(resIndex)
  return null

def is_conflict_with_server_preview(tm, box; exclude_eid : EntityId = INVALID_ENTITY_ID; base_collres : CollisionResource const? = null)
  var objectFound = false
  find_query() <| $ [es(REQUIRE=builder_server_preview)] (eid : EntityId;
                                                          transform : float3x4;
                                                          buildingBoxMin : float3;
                                                          buildingBoxMax : float3;
                                                          previewCollres : CollisionResource const?;
                                                          ri_preview__name : das_string const?)
    if eid == exclude_eid
      return false
    let serverPreviewCollres = get_building_collres(previewCollres, ri_preview__name)
    objectFound = check_bbox3_intersection(box, tm, BBox3(buildingBoxMin, buildingBoxMax), transform)
    if objectFound && serverPreviewCollres != null && base_collres != null
      var intersectPoint : float3
      objectFound = test_collres_intersection(*base_collres, tm, *serverPreviewCollres, transform, intersectPoint, intersectPoint, true)
    return objectFound
  return objectFound

def is_conflict_with_other_buildings(tm, box; exclude_eid : EntityId = INVALID_ENTITY_ID; base_collres : CollisionResource const? = null)
  var objectFound = false
  find_query() <| $ [es(REQUIRE=buildTypeId)] (eid : EntityId;
                                               transform : float3x4;
                                               ri_extra__bboxMin : float3;
                                               ri_extra__bboxMax : float3;
                                               previewCollres : CollisionResource const?;
                                               ri_extra__name : das_string const?)
    if eid == exclude_eid
      return false
    objectFound = check_bbox3_intersection(box, tm, BBox3(ri_extra__bboxMin, ri_extra__bboxMax), transform)
    let buildingCollres = get_building_collres(previewCollres, ri_extra__name)
    if objectFound && buildingCollres != null && base_collres != null
      var intersectPoint : float3
      objectFound = test_collres_intersection(*base_collres, tm, *buildingCollres, transform, intersectPoint, intersectPoint, true)
    return objectFound
  return objectFound

def is_conflict_with_objects_in_grid(tm, box; exclude_eid : EntityId = INVALID_ENTITY_ID; base_collres : CollisionResource const? = null)
  var objectFound = false
  let buildingWorldBox = BBox3(tm[3], length(box.width))
  find_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], buildingWorldBox, GridEntCheck BOUNDING) <| $(foundEid : EntityId)
    if foundEid == exclude_eid
      return false
    ecs::query(foundEid) <| $ [es] (collres : CollisionResource&;
                                    transform : float3x4;
                                    isAlive = false)
      if has(foundEid, "human") && !isAlive
        return
      let colBox = collres.vFullBBox
      let colBoxMin = colBox.bmin.xyz
      let colBoxMax = colBox.bmax.xyz
      let colBbox3 = BBox3(colBoxMin, colBoxMax)
      objectFound = check_bbox3_intersection(box, tm, colBbox3, transform)
      if objectFound && base_collres != null && !has(foundEid, "building__simplifiedCollisionCheck")
        var intersectPoint : float3
        objectFound = test_collres_intersection(collres, transform, *base_collres, tm, intersectPoint, intersectPoint, true)
    return objectFound
  return objectFound

def is_conflict_with_water(pos; height_limit : float)
  if height_limit < 0.f
    return false

  var waterLevel = 0.f;
  if traceht_water(pos, waterLevel)
    if waterLevel - pos.y > height_limit
      return true

  return false

def is_conflict_with_world(tm; collobj : CollisionObject; collobj_offset : float; base_collres : CollisionResource const? = null)
  if base_collres == null
    return false
  var tmCopy = tm
  tmCopy[3] = tmCopy[3] + normalize(tmCopy[1]) * collobj_offset
  return test_collision_world(collobj, tmCopy, (*base_collres).boundingSphere.r)

def is_conflict_objects_in_building_box(tm, box; collobj : CollisionObject; collobj_offset : float; exclude_eid : EntityId = INVALID_ENTITY_ID; base_collres : CollisionResource const? = null)
  let isConflict = (is_conflict_with_server_preview(tm, box, exclude_eid, base_collres) ||
                    is_conflict_with_other_buildings(tm, box, exclude_eid, base_collres) ||
                    is_conflict_with_objects_in_grid(tm, box, exclude_eid, base_collres) ||
                    is_conflict_with_world(tm, collobj, collobj_offset, base_collres))
  return isConflict

def soft_check_is_conflict_objects_in_building_box(tm : float3x4; box : BBox3)
  let isConflict = (is_conflict_with_server_preview(tm, box) ||
                    is_conflict_with_other_buildings(tm, box) ||
                    is_conflict_with_objects_in_grid(tm, box))
  return isConflict

def is_human_respawn_selector_in_radius_for_team(pos; radius; for_team)
  if radius < 0.0
    return false
  let radiusSq = square(radius)
  var isRespawnSelectorFound = false
  isRespawnSelectorFound =  find_query() <| $ [es(REQUIRE=(respawnIconType, autoRespawnSelector))] (respawn_icon__position : float3;
                                                                                                    respawnIconType : string;
                                                                                                    team : int;
                                                                                                    respawn_icon__active : bool)
    return respawnIconType == "human" && respawn_icon__active && team == for_team && length_sq(respawn_icon__position - pos) < radiusSq
  return isRespawnSelectorFound

def is_pos_inside_capture_point(pos; margin_distance; transform; capzone__approximateRadius; sphere_zone__radius)
  let distanceSq = length_sq(transform[3] - pos)
  if capzone__approximateRadius >= 0.f
    return distanceSq < square(margin_distance + capzone__approximateRadius)
  if sphere_zone__radius > 0.0
    let zoneToPoint = pos - transform[3]
    if length_sq(zoneToPoint) < square(margin_distance)
      return true
    // move the build point closer to the zone by margin_distance, check that position against a scaled sphere zone
    // we can't just add margin_distance to sphere_zone_radius as this way margin_distance will be affected by zone's scale
    let reducedZoneToPoint = zoneToPoint - normalize(zoneToPoint) * margin_distance
    let scaledDistanceSq = length_sq(rotate(inverse(transform), reducedZoneToPoint))
    return scaledDistanceSq < square(sphere_zone__radius)
  let halfDiag = length(transform[0] + transform[2]) * 0.5
  return distanceSq < square(margin_distance + halfDiag)

def is_distance_to_capture_points_valid(pos; min_distance; include_not_active = false)
  if min_distance < 0.0
    return true
  return !find_query() <| $ [es(REQUIRE=capzone)] (active : bool;
                                                   transform : float3x4;
                                                   capzone__approximateRadius = -1.0;
                                                   sphere_zone__radius = 0.0)
    if !active && !include_not_active
      return false
    return is_pos_inside_capture_point(pos, min_distance, transform, capzone__approximateRadius, sphere_zone__radius)

def is_in_building_restricted_zone_sector(pos : float3;
                                          zone_transform : float3x4;
                                          zone_max_angle : float;
                                          zone_min_distance : float)
  if zone_min_distance < 0.0 || zone_max_angle <= 0.0
    return false

  let offset = pos - zone_transform[3]

  if length_sq(offset) >= square(zone_min_distance)
    let cosAngle = safediv(dot(offset, -zone_transform[0]), length(offset) * length(zone_transform[0]))

    if cosAngle > cos(deg_to_rad(zone_max_angle))
      return true
  return false

def is_in_building_restricted_zone_sector(pos : float3;
                                          builder_team : int;
                                          zone_transform : float3x4;
                                          zone_max_angle : float;
                                          zone_min_distance_for_team_offense : float;
                                          zone_min_distance_for_team_defense : float;
                                          offense_team : int)
  if builder_team < 0
    return false

  var minDist : float
  if offense_team == builder_team
    minDist = zone_min_distance_for_team_offense
  else
    minDist = zone_min_distance_for_team_defense
  return is_in_building_restricted_zone_sector(pos,
                                               zone_transform,
                                               zone_max_angle,
                                               minDist)

def find_building_restricted_zone(pos : float3; builder_team : int)
  var res = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=buildingRestrictedZone)] (eid : EntityId;
                                                          transform aka restricted_zone_transform : float3x4;
                                                          building_restricted_zone__maxAngle : float = -1.;
                                                          building_restricted_zone__minDistanceForTeamOffense : float = -1.;
                                                          building_restricted_zone__minDistanceForTeamDefense : float = -1.;
                                                          capzone__trainOffenseTeam : int = TEAM_UNASSIGNED)
    if (is_point_in_capzone(pos, eid, 1.) ||
        is_in_building_restricted_zone_sector(pos,
                                              builder_team,
                                              restricted_zone_transform,
                                              building_restricted_zone__maxAngle,
                                              building_restricted_zone__minDistanceForTeamOffense,
                                              building_restricted_zone__minDistanceForTeamDefense,
                                              capzone__trainOffenseTeam))
      res = eid
      return true
    return false
  return res

def is_in_building_restricted_zone(pos : float3; builder_team : int)
  return !!find_building_restricted_zone(pos, builder_team)

def get_player_eid_interacting_building(building_eid, exclude_eid = INVALID_ENTITY_ID)
  var player_eid = INVALID_ENTITY_ID
  find_query() <| $ [es] (eid : EntityId; building_action__target : EntityId)
    if eid == exclude_eid
      return false
    if building_action__target == building_eid
      player_eid = eid
    return !!player_eid
  return player_eid

def is_not_attachable_gun(gun_eid : EntityId; transform : float3x4;
                          check_points_down : Point3List; check_points : Array)
  for pt in check_points_down
    var checkPt = transform * pt
    let dir = float3(0.0, -1.0, 0.0)
    var norm : float3
    var t = 10.0
    traceray_normalized(checkPt, dir, t, norm)
    checkPt += dir * t
    if gun_needs_detach(gun_eid, checkPt)
      return true
  for pt in check_points
    let obj = get_ecs_object(pt)
    if obj == null
      continue
    let from = transform * (*obj |> get_Point3("from") ?? float3())
    let to = transform * (*obj |> get_Point3("to") ?? float3())
    var norm : float3
    var t = length(from - to)
    let dir = normalize(to - from)
    if traceray_normalized(from, dir, t, norm)
      return true
  return false

def is_not_attachable_gun(building_eid : EntityId)
  var res = false
  query(building_eid) <| $ [es] (transform : float3x4;
                                 animchar : AnimcharBaseComponent;
                                 gun_autodetach__nodeId : int;
                                 gun_attachable_check__pointsFromTo : Array;
                                 gun_attachable_check__pointsDown : Point3List)
    var gunTm = transform
    if gun_autodetach__nodeId >= 0
      geomtree_getNodeWtmScalar(*animchar.nodeTree, gun_autodetach__nodeId, gunTm)
    res ||= is_not_attachable_gun(building_eid, gunTm,
                                  gun_attachable_check__pointsDown, gun_attachable_check__pointsFromTo)
  find_query() <| $ [es] (eid : EntityId;
                          animchar : AnimcharBaseComponent;
                          gun_autodetach__nodeId : int;
                          transform : float3x4;
                          gun_attachable_check__pointsFromTo : Array;
                          gun_attachable_check__pointsDown : Point3List;
                          dependsOnBuildingEid : EntityId)
    if dependsOnBuildingEid == building_eid
      var gunTm = transform
      if gun_autodetach__nodeId >= 0
        geomtree_getNodeWtmScalar(*animchar.nodeTree, gun_autodetach__nodeId, gunTm)
      res ||= is_not_attachable_gun(eid, gunTm,
                                    gun_attachable_check__pointsDown, gun_attachable_check__pointsFromTo)
      return true
    return false
  return res

def is_required_space_above_object_free(pos : float3; diameter : float; check_height : float; eps = 0.1)
  if check_height == 0.f
    return true
  let radius = 0.5 * diameter
  let poses = [[float3 pos;
                pos + float3(radius, 0.0, 0.0);
                pos + float3(-radius, 0.0, 0.0);
                pos + float3(0.0, 0.0, radius);
                pos + float3(0.0, 0.0, -radius)]]
  for curPos in poses
    let traceStart = curPos + float3(0.0, check_height + eps, 0.0)
    let dir = float3(0, -1, 0)
    if rayhit_normalized(traceStart, dir, check_height, ETF_ALL, -1)
      return false
  return true

def is_player_can_destroy_building(player_eid, player_team, building_eid)
  var canDestroy = true
  query(building_eid) <| $ [es(REQUIRE=undestroyableyByTeammates)] (buildByPlayer : EntityId)
    if buildByPlayer == player_eid
      return
    query(buildByPlayer) <| $ [es] (team : int)
      if is_teams_friendly(team, player_team)
        canDestroy = false
  return canDestroy

def count_available_buildings_by_type(player_eid : EntityId; currentPreviewId : int)
  var buildingsByType = -1
  if currentPreviewId >= 0
    query(player_eid) <| $ [es] (availableBuildings : IntList)
      if currentPreviewId < length(availableBuildings)
        buildingsByType = availableBuildings[currentPreviewId]
  return buildingsByType
