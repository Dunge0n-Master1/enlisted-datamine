require ecs
require EnlistedNet
require game.es.events
require game.utils.net_utils
require common_shooter.events_common_shooter
require ecs.common
require DagorSystem
require DagorMath
require math.base
require app
require strings
require EnlistedHuman
require EnlistedWeapon
require AnimV20
require game.utils.team
require GeomNodeTree
require DagorMathUtils
require Grid
require GridCollision
require CollisionTraces
require Dacoll
require PhysMat
require CollRes
require SmokeOccluder

struct PointsStruct
  eid : EntityId = INVALID_ENTITY_ID
  time : float

def delete_player_points(var points : array<PointsStruct>; count : int)
  if count <= 0
    for point in points
      send_net_event(point.eid, [[CmdDeleteMapUserPoint]])
  elif length(points) > count
    let numPoints = length(points) - count
    for _i in range(numPoints)
      var first = 0
      for j in range(1, length(points))
        if points[j].time < points[first].time
          first = j
      if points[first].eid != INVALID_ENTITY_ID
        send_net_event(points[first].eid, [[CmdDeleteMapUserPoint]])
        erase(points, first)

[es(tag=server, on_appear)]
def map_user_point_init_es(evt : Event;
                           eid : EntityId;
                           userPointOwner : EntityId;
                           pointGroup : int;
                           timer__start : float;
                           timer__delta : float;
                           var timer__destroy : float&;
                           countPoint : int = 1)
  timer__destroy = timer__start + timer__delta

  let renameUserPointOwner = userPointOwner
  let renameEid = eid
  let renamePointGroup = pointGroup
  var points : array<PointsStruct>

  query() <| $ [es] (eid : EntityId;
                     userPointOwner : EntityId;
                     timer__start : float;
                     pointGroup : int)
    if userPointOwner == renameUserPointOwner && eid != renameEid && pointGroup == renamePointGroup
      points |> emplace([[PointsStruct
        eid = eid,
        time = timer__start
      ]])

  delete_player_points(points, countPoint - 1)

def get_mark_object(user_points : Object; name : string; templateName : string)
  let objRef = get_ecs_object(user_points, name)
  if objRef == null
    logerr("user mark {name} not found in user_points object created from template {templateName}")
  return objRef

def is_cooldown(var last_time : float&;
                cooldown : float;
                var mark_count : int&;
                mark_limit : int)
  let curTime =  get_sync_time()
  let dt = curTime - last_time
  mark_count = max(0, mark_count - roundi(safediv(dt, cooldown)))
  if mark_count > mark_limit
    return true
  last_time = curTime
  mark_count++
  return false

def private is_human_visible(from : float3;
                             ray_tolerance : float;
                             transform : float3x4;
                             animchar : AnimcharBaseComponent;
                             collres : CollisionResource)
  let nodeCount = collres_get_nodesCount(collres)
  for i in range(nodeCount)
    let node = collres_get_node(collres, i)
    var nodeTm : float3x4
    collres_get_collision_node_tm(collres, i, transform, animchar.nodeTree, nodeTm)
    let to = nodeTm * node.modelBBox.center
    var dir = to - from
    let t = length(dir)
    dir *= safeinv(t)
    if t > ray_tolerance && rayhit_normalized(from, dir, t - ray_tolerance, ETF_DEFAULT, -1)
      continue
    return true
  return false

def find_enemy_on_ray(trace_pos : float3;
                      trace_dir : float3;
                      var dist : float&;
                      cylinder_rad : float;
                      max_angle_cos : float;
                      local_team : int;
                      skip_dead : bool)
  var bestEid = INVALID_ENTITY_ID
  var bestDot = max_angle_cos

  for_each_entity_in_grid(ecs_hash("humans"), trace_pos, trace_dir, dist, cylinder_rad, GridEntCheck BOUNDING) <| $(eid : EntityId; pos : float3)
    query(eid) <| $ [es] (team : int;
                          transform : float3x4;
                          animchar : AnimcharBaseComponent;
                          collres : CollisionResource;
                          isAlive : bool = true)
      if skip_dead && !isAlive
        return
      if is_teams_friendly(team, local_team)
        return
      if team == TEAM_UNASSIGNED
        return

      let dirToHuman = pos - trace_pos
      let distToHuman = length(dirToHuman)
      if distToHuman > dist
        return
      let dir = dirToHuman * safeinv(distToHuman)
      let dirDot = dot(dir, trace_dir)
      if dirDot < bestDot
        return
      if is_human_visible(trace_pos, 0.2f, transform, animchar, collres)
        bestEid = eid
        dist = distToHuman
        bestDot = dirDot
  return bestEid

def find_building_on_ray(player_team : int;
                         trace_pos : float3;
                         trace_dir : float3;
                         max_dist : float)
  var buildingEid = INVALID_ENTITY_ID
  var len = max_dist
  var norm : float3
  var pmid : int
  var riDesc = RendInstDesc()
  traceray_normalized(trace_pos, trace_dir, len, pmid, norm, ETF_DEFAULT, riDesc, -1)
  let trace_to = trace_pos + trace_dir * len
  query() <| $ [es(REQUIRE_NOT=(builder_preview, user_point__ignore))] (eid : EntityId;
                                                                        transform : float3x4;
                                                                        buildingRadius : float;
                                                                        building_menu__image : string;
                                                                        isAlive : bool = true;
                                                                        team : int = TEAM_UNASSIGNED;
                                                                        builder_info__team : int = TEAM_UNASSIGNED)
    let currentTeam = team != TEAM_UNASSIGNED ? team : builder_info__team
    if empty(building_menu__image) || !isAlive || is_teams_friendly(currentTeam, player_team)
      return
    if test_segment_sphere_intersection(trace_pos, trace_to, transform[3], buildingRadius)
      buildingEid = eid
  return buildingEid

def find_vehicle_on_ray(player_team : int;
                        var pos_mark : float3&;
                        var vehicle_eid : EntityId&;
                        var point_on_vehicle : bool&;
                        selected_vehicle : EntityId;
                        trace_pos : float3;
                        trace_dir : float3;
                        max_dist : float;
                        aim_ray_mat_id : int)
  var found = false
  var t = max_dist
  trace_entities_in_grid(ecs_hash("vehicles"), trace_pos, trace_dir, t, INVALID_ENTITY_ID, SortIntersections YES) <| $(intersections : array<IntersectedEntity>#)
    for it in intersections
      if selected_vehicle == it.eid
        continue
      query(it.eid) <| $ [es] (isAlive : bool = false; team = TEAM_UNASSIGNED; user_point__attachWithOffset : Tag const?)
        let ray_tolerance = 0.2f
        if it.t <= ray_tolerance || !rayhit_normalized(trace_pos, trace_dir, it.t - ray_tolerance, ETF_DEFAULT, aim_ray_mat_id)
          found = true
          pos_mark = trace_pos + trace_dir * it.t
          point_on_vehicle = user_point__attachWithOffset != null
          if (isAlive && !is_teams_friendly(team, player_team)) || point_on_vehicle
            vehicle_eid = it.eid
      if found
        break

  return !!vehicle_eid

def find_vehicle_around(player_team : int;
                        var pos_mark : float3&;
                        var vehicle_eid : EntityId&;
                        trace_pos : float3;
                        trace_dir : float3;
                        max_dist : float;
                        box_mult : float)
  var minDist = -1.
  let traceStopPos = trace_pos + trace_dir * max_dist
  query() <| $ [es(REQUIRE=vehicle, REQUIRE_NOT=deadEntity, REQUIRE_NOT=airplane)] (eid : EntityId;
                                                                                    transform : float3x4;
                                                                                    team : int;
                                                                                    collres : CollisionResource)
    if team == TEAM_UNASSIGNED || is_teams_friendly(team, player_team)
      return

    var intersection = false
    using() <| $(var box : bbox3f#)
      var bbox = transform * BBox3(collres.vFullBBox.bmin.xyz, collres.vFullBBox.bmax.xyz)
      bbox |> bbox3_inflate(box_mult)
      box.bmax = float4(bbox.boxMax.x, bbox.boxMax.y, bbox.boxMax.z, 1.)
      box.bmin = float4(bbox.boxMin.x, bbox.boxMin.y, bbox.boxMin.z, 1.)
      intersection = v_test_segment_box_intersection(trace_pos, traceStopPos, box) != 0

    if !intersection
      return

    let dist = length_sq(transform[3] - trace_pos)
    if minDist < 0. || dist < minDist
      minDist = dist
      vehicle_eid = eid
      pos_mark = transform[3]
  return !!vehicle_eid

def get_custom_mark_object(enemy_mark : Object; user_points : Object; mark_name : string)
  let fallbackMark = get_string(enemy_mark, "findEnemyNewMark", "")
  let mark = get_string(enemy_mark, mark_name, fallbackMark)
  return get_ecs_object(user_points, mark)

def create_map_user_point(point_type : string;
                          var pos : float3;
                          norm : float3;
                          eid : EntityId;
                          team : int;
                          obj : Object;
                          silent : bool;
                          attr : block<(var compInit : ComponentsInitializer) : void>)
  if length_sq(pos) == 0.f
    return INVALID_ENTITY_ID
  let templateName = get_string(obj, "templateName", "")
  if empty(templateName)
    return INVALID_ENTITY_ID

  let curTime = get_sync_time()
  pos.y += get_float(obj, "yOffset") ?? 0.f

  return createEntity(templateName) <| $(init)
    var tm = IDENT_TM
    if length_sq(norm) > FLT_EPSILON
      make_tm(dir_to_quat(norm), tm)
    tm[3] = pos
    invoke(attr, init)
    init |> set("transform", tm)
    init |> set("team", team)
    init |> set("userPointOwner", eid)
    init |> set("userPointType", point_type)
    init |> set("timer__start", curTime)
    init |> set("silentAppearance", silent)

[es(tag=server, REQUIRE=player)]
def map_user_point_create_es(evt : CmdCreateMapUserPoint;
                             team : int;
                             eid : EntityId;
                             possessed : EntityId;
                             user_points : Object;
                             var lastSetMarkTime : float&;
                             setMarkCooldown : float;
                             var lastMarkCount : int&;
                             setMarkLimit : int;
                             markerAroundBoxMult : float = 5f;
                             markerAroundMaxDist : float = 8000f;
                             marker__enemyDetectMaxDistance : float = 250f)
  if is_cooldown(lastSetMarkTime, setMarkCooldown, lastMarkCount, setMarkLimit)
    return

  var pos = evt.pos

  let templateName = getEntityTemplateName(eid)

  var obj = get_mark_object(user_points, evt.item_name, templateName)
  if null == obj
    return

  var isInAirplane = false
  var vehicleSelected = INVALID_ENTITY_ID
  var enemyDetectMaxDistance = marker__enemyDetectMaxDistance
  var humanAimTm = IDENT_TM
  var humanCurrentGunEid = INVALID_ENTITY_ID
  query(possessed) <| $ [es] (human__aimTm : float3x4;
                              human_weap__currentGunEid : EntityId;
                              human_anim__vehicleSelected : EntityId)
    humanAimTm = human__aimTm
    humanCurrentGunEid = human_weap__currentGunEid
    isInAirplane = has(human_anim__vehicleSelected, "airplane")
    vehicleSelected = human_anim__vehicleSelected
    query(human_anim__vehicleSelected) <| $ [es] (marker__enemyDetectMaxDistance : float = 300f)
      enemyDetectMaxDistance = marker__enemyDetectMaxDistance

  var aimPos = humanAimTm[3]
  var aimDir = humanAimTm[0]
  query(evt.markOwnerEid) <| $ [es] (transform : float3x4)
    aimPos = transform[3]
    aimDir = transform[0]

  let smokeTraceEnd = aimPos + aimDir * enemyDetectMaxDistance
  if rayhit_smoke_occluders(aimPos, smokeTraceEnd)
    return

  var enemyEid = INVALID_ENTITY_ID
  var vehicleEid = INVALID_ENTITY_ID
  var buildingEid = INVALID_ENTITY_ID
  var userPointCustomIcon : string
  var userPointVehicleTargetEid : EntityId = INVALID_ENTITY_ID
  var pointOnVehicle = false

  if has(*obj, "findEnemy")
    var aimRayMatId = PHYSMAT_INVALID
    query(humanCurrentGunEid) <| $ [es] (gun__aimRayMatId : int)
      aimRayMatId = gun__aimRayMatId

    let enemyDetectDegree = get_float(obj, "enemyDetectAngle") ?? 0.5f
    let enemyDetectCos = cos(deg_to_rad(enemyDetectDegree))
    let enemyDetectCylinderRad = get_float(obj, "enemyDetectCylinderRad") ?? 0.4f
    let START_OFFSET = 0.2f // or else we could hit the gun itself
    let traceDir = evt.dir
    let traceStart = aimPos + traceDir * START_OFFSET
    let skipDead = get_bool(obj, "skipDead") ?? false
    enemyEid = find_enemy_on_ray(traceStart, traceDir, enemyDetectMaxDistance, enemyDetectCylinderRad, enemyDetectCos, team, skipDead)
    if enemyEid != INVALID_ENTITY_ID
      pos = traceStart + traceDir * enemyDetectMaxDistance
      let findEnemyMark = get_string(obj, "findEnemyNewMark", "")
      if !empty(findEnemyMark)
        let newObj = get_ecs_object(user_points, findEnemyMark)
        if newObj != null
          obj = newObj
    buildingEid = find_building_on_ray(team, traceStart, traceDir, enemyDetectMaxDistance)
    if buildingEid != INVALID_ENTITY_ID
      query(buildingEid) <| $ [es] (transform : float3x4; building_menu__image : string)
        pos = transform[3]
        userPointCustomIcon = building_menu__image
        let newObj = get_custom_mark_object(*obj, user_points, "findEnemyBuildingNewMark")
        if newObj != null
          obj = newObj
    elif (isInAirplane
      ? find_vehicle_around(team, pos, vehicleEid, traceStart, traceDir, markerAroundMaxDist, markerAroundBoxMult)
      : find_vehicle_on_ray(team, pos, vehicleEid, pointOnVehicle, vehicleSelected, traceStart, traceDir, enemyDetectMaxDistance, aimRayMatId))
      query(vehicleEid) <| $ [es] (user_point__icon : string)
        userPointCustomIcon = user_point__icon
      let newTemplateName = pointOnVehicle ? "findEnemyPointOnVehicleNewMark" : "findEnemyVehicleNewMark"
      let newObj = get_custom_mark_object(*obj, user_points, newTemplateName)
      if newObj != null
        userPointVehicleTargetEid = vehicleEid
        obj = newObj
  create_map_user_point(evt.item_name, pos, evt.norm, eid, team, *obj, false) <| $(var init : ComponentsInitializer)
    if !empty(userPointCustomIcon)
      set(init, "userPointCustomIcon", userPointCustomIcon)
    if !!buildingEid
      set(init, "userPointTarget", buildingEid)
    query(userPointVehicleTargetEid) <| $ [es] (transform : float3x4)
      set(init, "userPointVehicleTargetEid", userPointVehicleTargetEid)
      if pointOnVehicle
        set(init, "userPointVehicleOffset", pos - transform[3])
