require ecs
require app
require strings
require RendInst
require RiDestr
require Dacoll
require DagorMath
require DagorMathUtils
require DagorSystem
require ecs.ecs_template
require gameObject

def remover_log(start_time : int64; msg : string)
  let elapsedTime = float(get_time_usec(start_time)) * 0.001
  let frameNo = int(get_dagor_frame_no())
  print("remover_log: ({format("%.2f", elapsedTime)}ms/{frameNo}) {msg}")


struct RemoveBox
  bp : float3
  px : float3
  py : float3
  pz : float3
  sz : float3
  nx : float3
  ny : float3
  nz : float3
  bb : bbox3f

def add_bbox_point(var bb_min : float3&; var bb_max : float3&; pt : float3)
  bb_min.x = min(bb_min.x, pt.x)
  bb_min.y = min(bb_min.y, pt.y)
  bb_min.z = min(bb_min.z, pt.z)
  bb_max.x = max(bb_max.x, pt.x)
  bb_max.y = max(bb_max.y, pt.y)
  bb_max.z = max(bb_max.z, pt.z)

def calc_rbox(transform : float3x4; dist_coef : float) : RemoveBox
  var rbox : RemoveBox
  rbox.bp = transform[3]
  let dx = transform[0] * dist_coef
  let dy = transform[1] * dist_coef
  let dz = transform[2] * dist_coef
  rbox.px = rbox.bp + dx
  rbox.py = rbox.bp + dy
  rbox.pz = rbox.bp + dz
  rbox.sz.x = length(dx) * 2.f
  rbox.sz.y = length(dy) * 2.f
  rbox.sz.z = length(dz) * 2.f
  rbox.nx = normalize(dx)
  rbox.ny = normalize(dy)
  rbox.nz = normalize(dz)
  var bbMin = rbox.bp
  var bbMax = rbox.bp
  add_bbox_point(bbMin, bbMax, rbox.bp + dx + dy + dz)
  add_bbox_point(bbMin, bbMax, rbox.bp - dx + dy + dz)
  add_bbox_point(bbMin, bbMax, rbox.bp + dx - dy + dz)
  add_bbox_point(bbMin, bbMax, rbox.bp - dx - dy + dz)
  add_bbox_point(bbMin, bbMax, rbox.bp + dx + dy - dz)
  add_bbox_point(bbMin, bbMax, rbox.bp - dx + dy - dz)
  add_bbox_point(bbMin, bbMax, rbox.bp + dx - dy - dz)
  add_bbox_point(bbMin, bbMax, rbox.bp - dx - dy - dz)
  rbox.bb.bmin = float4(bbMin, 0.f)
  rbox.bb.bmax = float4(bbMax, 0.f)
  return rbox

def is_sphere_intersects_rbox(center : float3; radius : float; rbox : RemoveBox)
  let dx = dot(rbox.nx, center) - dot(rbox.nx, rbox.px)
  let dy = dot(rbox.ny, center) - dot(rbox.ny, rbox.py)
  let dz = dot(rbox.nz, center) - dot(rbox.nz, rbox.pz)
  if dx < -rbox.sz.x - radius || dx > radius
    return false
  if dy < -rbox.sz.y - radius || dy > radius
    return false
  if dz < -rbox.sz.z - radius || dz > radius
    return false
  return true

def find_ladder_eid(id : uint)
  var outEid = INVALID_ENTITY_ID
  find_query() <| $ [es] (eid : EntityId; ladder__sceneIndex : uint)
    if ladder__sceneIndex == id
      outEid = eid
      return true
    return false
  return outEid

def scan_scenery(transform : float3x4; dist_coef : float; var scanned : StringList&)
  let MAX_SCANNED_AMOUNT = 100
  scanned |> clear()
  let rbox = calc_rbox(transform, dist_coef)
  let poolsCount = rendinst_getRiGenExtraResCount()
  for pool_id in range(poolsCount)
    let riName = riex_getRIGenExtraName(uint(pool_id))
    var count = 0
    getRiGenExtraInstances(pool_id, rbox.bb) <| $(handles : array<riex_handle_t>#)
      for handle in handles
        let bsph = getRIGenExtraBSphere(handle)
        let bpos = float3(bsph.x, bsph.y, bsph.z)
        let brad = abs(bsph.w)
        if is_sphere_intersects_rbox(bpos, brad, rbox)
          ++count
          if count == 1
            if length(scanned) < MAX_SCANNED_AMOUNT
              scanned |> push(riName)
            elif length(scanned) == MAX_SCANNED_AMOUNT
              scanned |> push("...")

  query() <| $ [es] (game_objects : GameObjects)
    if game_objects.ladders == null
      return
    tiled_scene_boxCull(*game_objects.ladders, rbox.bb, /*use_flags*/uint(0), /*use_pools*/uint(0)) <| $ [unused_argument(m)] (index : uint; m : mat44f)
      scanned |> push("ladder<{int(index)}>")


def remove_scenery(transform : float3x4; dist_coef : float; excludes : StringList; keep_ri_with_entity : bool)
  let startTime = ref_time_ticks()

  var excludesMap : table<string; bool>
  for exclude in excludes
    excludesMap[string(exclude)] = true

  var count = 0
  let rbox = calc_rbox(transform, dist_coef)
  let poolsCount = rendinst_getRiGenExtraResCount()
  for pool_id in range(poolsCount)
    let riName = riex_getRIGenExtraName(uint(pool_id))
    if key_exists(excludesMap, riName)
      continue
    getRiGenExtraInstances(pool_id, rbox.bb) <| $(handles : array<riex_handle_t>#)
      for handle in handles
        if !riex_isRiGenExtraValid(handle)
          continue
        if keep_ri_with_entity && find_ri_extra_eid(handle) != INVALID_ENTITY_ID
          continue
        let bsph = getRIGenExtraBSphere(handle)
        let bpos = float3(bsph.x, bsph.y, bsph.z)
        let brad = abs(bsph.w)
        if is_sphere_intersects_rbox(bpos, brad, rbox)
          var out_desc = RendInstDesc()
          destroyRendinst(RendInstDesc(handle), out_desc)
          rendinst_delRIGenExtra(out_desc.riExtraHandle)
          ++count

  var removedLaddersCount = 0
  query() <| $ [es] (var game_objects : GameObjects&)
    if game_objects.ladders == null
      return
    tiled_scene_boxCull(*game_objects.ladders, rbox.bb, /*use_flags*/uint(0), /*use_pools*/uint(0)) <| $ [unused_argument(m)] (index : uint; m : mat44f)
      if keep_ri_with_entity && find_ladder_eid(index) != INVALID_ENTITY_ID
        return
      destroy(*game_objects.ladders, index)
      ++removedLaddersCount

  remover_log(startTime, "removed {count} instances and ladders {removedLaddersCount}")

def damage_scenery(transform : float3x4; dist_coef : float)
  let rad = min(length(transform[0]), min(length(transform[1]), length(transform[2])))
  let sph = BSphere3(transform[3], rad * dist_coef)
  let axis : float3
  rendinst_doRIGenDamage(sph, get_dagor_frame_no(), axis)


[ecs_template]
struct scenery_remover_netclient_finalize
  nonCreatableObj : bool = true
  scenery_remover_netclient_finalize__eid  : EntityId
  scenery_remover_netclient_finalize__time : float

[es(tag=netClient, on_appear)]
def scenery_remover_on_replicated_to_client_es(evt : Event;
                                               eid : EntityId;
                                               scenery_remove__netClientApply : bool;
                                               scenery_remove__exclude : StringList;
                                               scenery_remove__distCoef : float;
                                               transform : float3x4)
  if scenery_remove__netClientApply
    remove_scenery(transform, scenery_remove__distCoef, scenery_remove__exclude, true)

    // NOTE: Have to do all remove_scenery() before any damage_scenery() to avoid debris logerrs
    let delayDamageSceneryTime = 0.1
    createEntity("scenery_remover_netclient_finalize") <| $(var init : ComponentsInitializer)
      set(init, "scenery_remover_netclient_finalize__eid", eid)
      set(init, "scenery_remover_netclient_finalize__time", get_sync_time() + delayDamageSceneryTime)

[es(tag=netClient, no_order)]
def scenery_remover_on_netclient_finalize_client_es(info : UpdateStageInfoAct;
                                                    eid : EntityId;
                                                    scenery_remover_netclient_finalize__eid : EntityId;
                                                    scenery_remover_netclient_finalize__time : float)
  if info.curTime < scenery_remover_netclient_finalize__time
    return
  query(scenery_remover_netclient_finalize__eid) <| $ [es] (scenery_remove__distCoef : float;
                                                            transform : float3x4)
    damage_scenery(transform, scenery_remove__distCoef)
  destroyEntity(eid)


[es(tag=server, on_event=EventLevelLoaded, before=(obstacle_level_ri_loaded_es, ri_extra_gen_blk_es))]
def scenery_remover_on_level_loaded_es(evt : Event)
  query() <| $ [es] (scenery_remove__apply : bool;
                     scenery_remove__exclude : StringList;
                     scenery_remove__distCoef : float;
                     transform : float3x4)
    if scenery_remove__apply
      remove_scenery(transform, scenery_remove__distCoef, scenery_remove__exclude, true)

  // NOTE: Have to do all remove_scenery() before any damage_scenery() to avoid debris logerrs

  query() <| $ [es] (var scenery_remove__apply : bool&;
                     var scenery_remove__netClientApply : bool&;
                     scenery_remove__distCoef : float;
                     transform : float3x4)
    if scenery_remove__apply
      scenery_remove__apply = false
      scenery_remove__netClientApply = true
      damage_scenery(transform, scenery_remove__distCoef)

[es(tag=server, on_appear, REQUIRE=gameObject)]
def scenery_remover_on_game_object_es(evt : Event; eid : EntityId; transform aka obj_transform : float3x4)
  query() <| $ [es] (scenery_remove__apply : bool&;
                     scenery_remove__netClientApply : bool&;
                     scenery_remove__distCoef : float;
                     transform aka remove_transform : float3x4)
    if scenery_remove__apply || scenery_remove__netClientApply
      let rbox = calc_rbox(remove_transform, scenery_remove__distCoef)
      if is_sphere_intersects_rbox(obj_transform[3], 0.0, rbox)
        destroyEntity(eid)


// for Editor only
[es(tag=gameClient, track=scenery_remove__apply)]
def scenery_remover_on_apply_es(evt : Event;
                                var scenery_remove__apply : bool&;
                                scenery_remove__exclude : StringList;
                                scenery_remove__distCoef : float;
                                transform : float3x4)
  if scenery_remove__apply
    scenery_remove__apply = false
    remove_scenery(transform, scenery_remove__distCoef, scenery_remove__exclude, false)
    damage_scenery(transform, scenery_remove__distCoef)

// for Editor only
[es(tag=gameClient, track=scenery_remove__scan)]
def scenery_remover_on_scan_es(evt : Event;
                               var scenery_remove__scan : bool&;
                               var scenery_remove__scanned : StringList;
                               scenery_remove__distCoef : float;
                               transform : float3x4)
  if scenery_remove__scan
    scenery_remove__scan = false
    scan_scenery(transform, scenery_remove__distCoef, scenery_remove__scanned)
