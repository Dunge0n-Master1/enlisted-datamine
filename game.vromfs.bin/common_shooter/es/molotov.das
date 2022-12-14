require ecs
require app
require math
require math.base
require game.es.events
require Dacoll
require GridCollision
require CollisionTraces
require game.es.node_attach_common
require AnimV20
require CollRes
require common_shooter.events_common_shooter
require DagorMathUtils
require DagorRandom

struct MolotovShellInfo
  ownerEid : EntityId
  gunPropsId : int
  shellId : int

def get_fire_time_left(start_at_time, spread_time, full_force_time, fade_time : float)
  return max(0.0, start_at_time + spread_time + full_force_time + fade_time - get_sync_time())

def get_increased_fire_full_force_time(tmplt : string; add_time : float)
  var fireTemplate = getTemplateByName(tmplt)
  if fireTemplate == null
    fireTemplate = buildTemplateByName(tmplt)
    if fireTemplate == null
      return 0.0
  let fullTime = get_float(getTemplateComponent(*fireTemplate, "fire_source__fullForceTime")) ?? 0.0
  let maxFullTime = get_float(getTemplateComponent(*fireTemplate, "fire_source__maxFullForceTime")) ?? fullTime

  return min(fullTime + add_time, maxFullTime)

def create_fire_impl(pos : float3; tmplt : string; shell_info : MolotovShellInfo; add_time : float)
  return createEntity(tmplt) <| $(var init : ComponentsInitializer)
    var tm = IDENT_TM
    tm[3] = pos
    set(init, "transform", tm)
    set(init, "fire_source__fullForceTime", get_increased_fire_full_force_time(tmplt, add_time))
    set(init, "dmgzone__offender", shell_info.ownerEid)
    set(init, "dmgzone__gunPropsId", shell_info.gunPropsId)
    set(init, "dmgzone__shellId", shell_info.shellId)

def absorb_closeby_fires(pos : float3; min_distance_between_sq : float)
  var increasedTime = 0.0
  query() <| $ [es(REQUIRE=fire_source, REQUIRE_NOT=node_attached__entity)] (eid : EntityId;
                                                                             transform : float3x4;
                                                                             fire_source__startTime : float;
                                                                             fire_source__spreadTime : float;
                                                                             fire_source__fullForceTime : float;
                                                                             fire_source__fadeTime : float)
    if length_sq(pos - transform[3]) < min_distance_between_sq
      destroyEntity(eid)
      increasedTime += get_fire_time_left(fire_source__startTime, fire_source__spreadTime, fire_source__fullForceTime, fire_source__fadeTime)
  return increasedTime

def absorb_closeby_attached_fires(pos : float3; min_distance_between_sq : float; binded_to_eid : EntityId)
  var increasedTime = 0.0
  query() <| $ [es(REQUIRE=fire_source)] (eid : EntityId;
                                          transform : float3x4;
                                          node_attached__entity : EntityId;
                                          fire_source__startTime : float;
                                          fire_source__spreadTime : float;
                                          fire_source__fullForceTime : float;
                                          fire_source__fadeTime : float)
    if node_attached__entity == binded_to_eid && length_sq(pos - transform[3]) < min_distance_between_sq
      destroyEntity(eid)
      increasedTime += get_fire_time_left(fire_source__startTime, fire_source__spreadTime, fire_source__fullForceTime, fire_source__fadeTime)
  return increasedTime

def create_fire(pos : float3; tmplt : string; shell_info : MolotovShellInfo; min_distance_between_sq : float; var fires : array<float3>)
  var found = false
  for otherFirePos in fires
    if length_sq(pos - otherFirePos) < min_distance_between_sq
      found = true
      break
  if found
    return
  push(fires, pos)

  let increasedTime = absorb_closeby_fires(pos, min_distance_between_sq)
  create_fire_impl(pos, tmplt, shell_info, increasedTime)

def attach_fire(pos : float3;
                bindToEid : ecs::EntityId;
                collNodeId : int;
                tmplt : string;
                shell_info : MolotovShellInfo;
                min_distance_between_sq : float;
                var attached_fires : array<tuple<EntityId; float3> >)
  var found = false
  for otherFire in attached_fires
    let otherFireEid = otherFire._0
    let otherFirePos = otherFire._1
    if otherFireEid == bindToEid && length_sq(pos - otherFirePos) < min_distance_between_sq
      found = true
      break
  if found
    return
  push(attached_fires, [[auto bindToEid, pos]])

  var localPos = pos
  var nodeId = 0
  query(bindToEid) <| $ [es] (animchar : AnimcharBaseComponent;
                              collres : CollisionResource;
                              fire_attach_excludes__nodeIds : IntList)
    for coll_whell_id in fire_attach_excludes__nodeIds
      if coll_whell_id == collNodeId
        return
    let node = collres_get_node(collres, collNodeId)
    nodeId = uint(node.geomNodeId) < uint(animchar.nodeTree.nodeCount) ? int(node.geomNodeId) : 0
  if !get_node_local_pos(bindToEid, nodeId, localPos)
    return

  let increasedTime = absorb_closeby_attached_fires(pos, min_distance_between_sq, bindToEid)
  let createdFireEid = create_fire_impl(pos, tmplt, shell_info, increasedTime)
  attach_to_node_pos(createdFireEid, bindToEid, nodeId, localPos)

def create_fire_on_object_ray(pos : float3; dir : float3; max_distance : float; tmplt : string; shell_info : MolotovShellInfo; min_distance_between_sq : float;
                              var attached_fires : array<tuple<EntityId; float3> >) : bool
  var created = false
  var t = max_distance
  trace_entities_in_grid(ecs_hash("vehicles"), pos, dir, t, INVALID_ENTITY_ID, SortIntersections YES) <| $(intersections : array<IntersectedEntity>#)
    for it in intersections
      if it.depth > 0
        continue

      attach_fire(it.pos, it.eid, it.collNodeId, tmplt, shell_info, min_distance_between_sq, attached_fires)
      created = true
      break
  return created

def create_fire_on_ground_ray(pos : float3; dir : float3; max_distance : float; tmplt : string; shell_info : MolotovShellInfo; min_distance_between_sq : float; var fires : array<float3>)
  var t = max_distance
  var norm : float3
  if traceray_normalized(pos, dir, t, norm, ETF_ALL)
    create_fire(pos + dir * t, tmplt, shell_info, min_distance_between_sq, fires)
    return true
  return false

def create_fire_on_trace(pos : float3; dir : float3; max_distance : float; tmplt : string; shell_info : MolotovShellInfo; min_distance_between_sq : float;
                         var fires : array<float3>; var attached_fires : array<tuple<EntityId; float3> >)
  if create_fire_on_object_ray(pos, dir, max_distance, tmplt, shell_info, min_distance_between_sq, attached_fires)
    return true
  return create_fire_on_ground_ray(pos, dir, max_distance, tmplt, shell_info, min_distance_between_sq, fires)

def get_spread_dirs(tm : float3x4; molotov_spread : ecs::Point3List)
  var spread_dirs : array<float3>
  for i in iter_range(molotov_spread)
    assume spread = molotov_spread[i]
    let azimuth = spread.x * DEG_TO_RAD
    let elevation = spread.y * DEG_TO_RAD
    var sinElevation, cosElevation, sinAzimuth, cosAzimuth : float
    sincos(elevation, sinElevation, cosElevation)
    sincos(azimuth, sinAzimuth, cosAzimuth)
    let rayLocal = float3(cosElevation * cosAzimuth, sinElevation, cosElevation * sinAzimuth)
    push(spread_dirs, tm * rayLocal)
  return <- spread_dirs

def get_global_spread_dirs(dir : float3; molotov_spread : ecs::Point3List)
  let yaxis = float3(0.0, 1.0, 0.0)
  let zaxis = normalize_default(cross(normalize(dir), yaxis), float3(0, 0, 1))
  let xaxis = cross(yaxis, zaxis)

  var tm : float3x4
  tm[0] = xaxis
  tm[1] = yaxis
  tm[2] = zaxis

  return <- get_spread_dirs(tm, molotov_spread)

def get_local_spread_dirs(dir : float3; molotov_spread : ecs::Point3List)
  let up = float3(0.0, 1.0, 0.0)
  let xaxis = normalize(dir)
  let zaxis = normalize_default(cross(xaxis, up), float3(0, 0, 1))
  let yaxis = cross(zaxis, xaxis)

  var tm : float3x4
  tm[0] = xaxis
  tm[1] = yaxis
  tm[2] = zaxis

  return <- get_spread_dirs(tm, molotov_spread)

def create_fire_on_dirs(pos : float3; dirs : array<float3>; spread_data : ecs::Point3List; tmplt : string; shell_info : MolotovShellInfo;
                        min_distance_between_sq : float; var fires : array<float3>; var attached_fires : array<tuple<EntityId; float3> >)
  for dir, spread in dirs, spread_data
    create_fire_on_trace(pos, dir, spread.z, tmplt, shell_info, min_distance_between_sq, fires, attached_fires)

def explode_molotov(var pos : float3;
                    speed_dir : float3;
                    tmplt : string;
                    shell_info : MolotovShellInfo;
                    minHeight : float;
                    spread_local : ecs::Point3List;
                    spread_global : ecs::Point3List;
                    max_fire_drop_height : float;
                    min_distance_between_sq : float)
  var fires : array<float3>
  var attached_fires : array<tuple<EntityId; float3> >
  var height = max_fire_drop_height
  tracedown_normalized(pos, height, ETF_DEFAULT)
  if height < minHeight
    pos.y += (minHeight - height)
    height = minHeight

  create_fire_on_dirs(pos, get_local_spread_dirs(speed_dir, spread_local), spread_local, tmplt, shell_info, min_distance_between_sq, fires, attached_fires)
  create_fire_on_dirs(pos, get_global_spread_dirs(speed_dir, spread_global), spread_global, tmplt, shell_info, min_distance_between_sq, fires, attached_fires)

  if !create_fire_on_trace(pos, float3(0.0, -1.0, 0.0), height, tmplt, shell_info, min_distance_between_sq, fires, attached_fires)
    create_fire(pos - float3(0.0, height, 0.0), tmplt, shell_info, min_distance_between_sq, fires)

[es(tag=server)]
def molotov_exploded(evt : CmdShellExplode;
                     shell__owner : EntityId;
                     shell__gun_props_id : int;
                     shell__shell_id__shell_id : int;
                     on_exploded__create : string;
                     molotov_spread__globalRays : ecs::Point3List;
                     molotov_spread__localRays : ecs::Point3List;
                     molotov_spread__minHeight : float = 0.2;
                     molotov_fire__minDistanceBetween : float = 0.5;
                     molotov_spread__dropMaxHeight : float = 20.0;
                     molotov_spread__stepBack : float = 0.2)
  let shellInfo = [[MolotovShellInfo ownerEid   = shell__owner,
                                     gunPropsId = shell__gun_props_id,
                                     shellId    = shell__shell_id__shell_id]]
  let dir = normalize_default(evt.vel, float3(1, 0, 0))
  let start = evt.position - dir * molotov_spread__stepBack
  explode_molotov(start, dir, on_exploded__create, shellInfo,
                  molotov_spread__minHeight, molotov_spread__localRays, molotov_spread__globalRays,
                  molotov_spread__dropMaxHeight, square(molotov_fire__minDistanceBetween))

def get_random_spread_dir(dir : float3; yaw, pitch : float2)
  var dirAngles = dir_to_angles(dir)
  dirAngles.x += deg_to_rad(rnd_float(yaw.x, yaw.y))
  dirAngles.y += deg_to_rad(rnd_float(pitch.x, pitch.y))
  return normalize(angles_to_dir(dirAngles))

[es(tag=server, on_appear)]
def explosion_spread_static_dir_init(evt : Event;
                                     explosion_spread__staticDir : float3;
                                     var on_explosion__dir : float3&)
  on_explosion__dir = explosion_spread__staticDir

[es(tag=server, on_appear, after=explosion_spread_static_dir_init)]
def explosion_spread_static_pos_init(evt : Event;
                                     explosion_spread__stepBack : float;
                                     on_explosion__dir : float3;
                                     var on_explosion__pos : float3&)
  on_explosion__pos = on_explosion__pos - on_explosion__dir * explosion_spread__stepBack

[es(tag=server, no_order)]
def explosion_spread_update(info : UpdateStageInfoAct;
                            eid : EntityId;
                            on_explosion__owner : EntityId;
                            on_explosion__gunPropsId : int;
                            on_explosion__shellId : int;
                            on_explosion__pos : float3;
                            on_explosion__dir : float3;
                            explosion_spread__createOnTrace : string;
                            explosion_spread__minDistanceBetween : float;
                            explosion_spread__upLengthMult : float;
                            explosion_spread__downLengthMult : float;
                            explosion_spread__downDirAdd : float;
                            explosion_spread__yaw : float2;
                            explosion_spread__pitch : float2;
                            explosion_spread__length : float2;
                            var explosion_spread__traceCount : int&)
  if explosion_spread__traceCount <= 0
    destroyEntity(eid)
    return
  explosion_spread__traceCount -= 1

  let shellInfo = [[MolotovShellInfo ownerEid   = on_explosion__owner,
                                     gunPropsId = on_explosion__gunPropsId,
                                     shellId    = on_explosion__shellId]]
  var fires : array<float3>
  var attached_fires : array<tuple<EntityId; float3> >
  let dir = get_random_spread_dir(on_explosion__dir, explosion_spread__yaw, explosion_spread__pitch)
  let len = rnd_float(explosion_spread__length.x, explosion_spread__length.y)
  let upLen = len * explosion_spread__upLengthMult

  if !create_fire_on_trace(on_explosion__pos, dir, upLen, explosion_spread__createOnTrace, shellInfo, square(explosion_spread__minDistanceBetween), fires, attached_fires)
    let pos = on_explosion__pos + dir * upLen
    let downDir = normalize(float3(dir.x, -abs(dir.y) + explosion_spread__downDirAdd, dir.z))
    let downLen = len * explosion_spread__downLengthMult
    create_fire_on_trace(pos, downDir, downLen, explosion_spread__createOnTrace, shellInfo, square(explosion_spread__minDistanceBetween), fires, attached_fires)
