require ecs
require app
require strings
require sandbox.es.navmesh_rebuild_events
require DagorMath
require DagorConsole
require DagorEditor
require pathfinder
require RendInst

let
  MIN_NAVMESH_INVALIDATE_HEIGHT = -10000.0
  MAX_NAVMESH_INVALIDATE_HEIGHT =  10000.0

def navmesh_rebuild_add_rirmv(tm, name)
  let poolsCount = rendinst_getRiGenExtraResCount()
  for pool_id in range(poolsCount)
    let riName = riex_getRIGenExtraName(uint(pool_id))
    if riName == name
      let bsph = getRIGenExtraBSphereByTM(uint(pool_id), tm)
      let pt1 = float3(bsph.x - bsph.w, MIN_NAVMESH_INVALIDATE_HEIGHT, bsph.z - bsph.w)
      let pt2 = float3(bsph.x + bsph.w, MAX_NAVMESH_INVALIDATE_HEIGHT, bsph.z + bsph.w)
      let bbox = BBox3(pt1, pt2)
      rebuildNavMesh_addBBox(bbox)
      return

def navmesh_rebuild_add_rirmvs(ri_list : Array)
  for ri in ri_list
    let obj = get_ecs_object(ri)
    if obj == null
      continue
    let tm = get_TMatrix(*obj, "tm")
    if tm == null
      continue
    let name = get_string(*obj, "name", "")
    navmesh_rebuild_add_rirmv(*tm, name)

def navmesh_rebuild_add_riextra(ri_extra : RiExtraComponent)
  let bsph = getRIGenExtraBSphere(ri_extra.handle)
  let pt1 = float3(bsph.x - bsph.w, MIN_NAVMESH_INVALIDATE_HEIGHT, bsph.z - bsph.w)
  let pt2 = float3(bsph.x + bsph.w, MAX_NAVMESH_INVALIDATE_HEIGHT, bsph.z + bsph.w)
  let bbox = BBox3(pt1, pt2)
  rebuildNavMesh_addBBox(bbox)


[es(tag=server)]
def navmesh_rebuild_cancel_es(evt : CmdNavMeshRebuildCancel)
  var rebuildingEid = INVALID_ENTITY_ID
  find_query() <| $ [es, unused_argument(navmesh_rebuilding__startTime)] (eid : EntityId; navmesh_rebuilding__startTime : int64)
    rebuildingEid = eid
    return true
  if rebuildingEid == INVALID_ENTITY_ID
    console_print("navmesh_rebuild: not running")
    return
  broadcastEvent([[EventNavMeshRebuildCancelled]])
  destroyEntity(rebuildingEid)
  rebuildNavMesh_close()
  console_print("navmesh_rebuild: cancelled")

[es(tag=server)]
def navmesh_rebuild_start_es(evt : CmdNavMeshRebuildStart)
  var rebuildingEid = INVALID_ENTITY_ID
  find_query() <| $ [es, unused_argument(navmesh_rebuilding__startTime)] (eid : EntityId; navmesh_rebuilding__startTime : int64)
    rebuildingEid = eid
    return true
  if rebuildingEid != INVALID_ENTITY_ID
    broadcastEvent([[EventNavMeshRebuildCancelled]])
    destroyEntity(rebuildingEid)
    rebuildNavMesh_close()
    console_print("navmesh_rebuild: was running, cancelled")

  rebuildNavMesh_init()

  find_query() <| $ [es] (nav_rebuild__agentMaxSlope : float)
    rebuildNavMesh_setup("agentMaxSlope", nav_rebuild__agentMaxSlope)
    return true
  find_query() <| $ [es] (nav_rebuild__vertsPerPoly : int)
    rebuildNavMesh_setup("vertsPerPoly", float(nav_rebuild__vertsPerPoly))
    return true
  find_query() <| $ [es] (nav_rebuild__regionMinSize : float)
    rebuildNavMesh_setup("regionMinSize", nav_rebuild__regionMinSize)
    return true
  find_query() <| $ [es] (nav_rebuild__regionMergeSize : float)
    rebuildNavMesh_setup("regionMergeSize", nav_rebuild__regionMergeSize)
    return true
  find_query() <| $ [es] (nav_rebuild__minBorderSize : int)
    rebuildNavMesh_setup("minBorderSize", float(nav_rebuild__minBorderSize))
    return true
  find_query() <| $ [es] (nav_rebuild__detailSampleDist : float)
    rebuildNavMesh_setup("detailSampleDist", nav_rebuild__detailSampleDist)
    return true
  find_query() <| $ [es] (nav_rebuild__detailSampleMaxError : float)
    rebuildNavMesh_setup("detailSampleMaxError", nav_rebuild__detailSampleMaxError)
    return true
  find_query() <| $ [es] (nav_rebuild__edgeMaxLen : float)
    rebuildNavMesh_setup("edgeMaxLen", nav_rebuild__edgeMaxLen)
    return true
  find_query() <| $ [es] (water__level : float)
    rebuildNavMesh_setup("waterLevel", water__level)
    return true

  query() <| $ [es] (elevs : Array)
    for elev in elevs
      let data = get_Point4(elev) ?? float4(0.0, 0.0, 0.0, 0.0)
      let pos = float3(data.x, 0.0, data.y)
      let rad = data.z
      var bbox = BBox3(pos, 2.0 * rad)
      bbox.boxMin.y = MIN_NAVMESH_INVALIDATE_HEIGHT
      bbox.boxMax.y = MAX_NAVMESH_INVALIDATE_HEIGHT
      rebuildNavMesh_addBBox(bbox)

  query() <| $ [es] (rirmv : Array; riunb : Array)
    navmesh_rebuild_add_rirmvs(rirmv)
    navmesh_rebuild_add_rirmvs(riunb)

  query() <| $ [es(REQUIRE=unbakedRendInstTag)] (ri_extra : RiExtraComponent)
    navmesh_rebuild_add_riextra(ri_extra)

  query() <| $ [es(REQUIRE=gameRendInstTag)] (ri_extra : RiExtraComponent)
    navmesh_rebuild_add_riextra(ri_extra)

  createEntitySync("navmesh_rebuilding")
  console_print("navmesh_rebuild: started")
  broadcastEvent([[EventNavMeshRebuildStarted]])


[es(tag=server, on_appear)]
def navmesh_rebuild_begin_es(evt : Event; var navmesh_rebuilding__startTime : int64&)
  navmesh_rebuilding__startTime = ref_time_ticks()

[es(tag=server, no_order)]
def navmesh_rebuild_step_es(info : UpdateStageInfoAct;
                            eid : EntityId;
                            navmesh_rebuilding__startTime : int64;
                            var navmesh_rebuilding__progress : int&;
                            var navmesh_rebuilding__errors : int&)
  if rebuildNavMesh_getProgress() >= 100
    let totalTime = float(get_time_usec(navmesh_rebuilding__startTime)) * 0.001
    let totalTiles = rebuildNavMesh_getTotalTiles()
    console_print("navmesh_rebuild: complete, {totalTiles} tiles in {format("%.2f", totalTime)}ms")
    broadcastEvent([[EventNavMeshRebuildComplete totalTime=totalTime, totalTiles=totalTiles, numErrors=navmesh_rebuilding__errors]])
    destroyEntity(eid)

    let sceneFilePath = entity_obj_editor_getSceneFilePath()
    if starts_with(sceneFilePath, "userGameMods/") && ends_with(sceneFilePath, "/scene.blk")
      let navMeshFileName = "patch_nav_mesh.bin"
      let navMeshFilePath = "{slice(sceneFilePath, 0, length(sceneFilePath)-10)}/{navMeshFileName}"
      if rebuildNavMesh_saveToFile(navMeshFilePath)
        console_print("navmesh_rebuild: saved to file {navMeshFilePath}")
        query() <| $ [es] (eid : EntityId; var level__patchNavMeshPath : das_string&)
          let levelPatchNavMeshPath = "%ugm/{navMeshFileName}"
          if level__patchNavMeshPath != levelPatchNavMeshPath
            level__patchNavMeshPath := levelPatchNavMeshPath
            entity_obj_editor_saveComponent(eid, "level__patchNavMeshPath")
            console_print("navmesh_rebuild: set to level entity component level__patchNavMeshPath <- '{level__patchNavMeshPath}'")
            console_print("navmesh_rebuild: please, save scene to use generated navmesh patch in future")
      else
        console_print("navmesh_rebuild: failed save to file {navMeshFilePath}")
    else
      console_print("navmesh_rebuild: not user mod scene, don't save to file")

    rebuildNavMesh_close()
    return

  let result = rebuildNavMesh_update(true)

  if !result
    navmesh_rebuilding__errors += 1

  let progress = rebuildNavMesh_getProgress()

  if navmesh_rebuilding__progress < progress
    navmesh_rebuilding__progress = progress
    let totalTime = float(get_time_usec(navmesh_rebuilding__startTime)) * 0.001
    let totalTiles = rebuildNavMesh_getTotalTiles()
    console_print("navmesh_rebuild: {format("%.2f", totalTime)}ms, {progress}%")
    broadcastEvent([[EventNavMeshRebuildProgress progress=float(progress), totalTime=totalTime, totalTiles=totalTiles, numErrors=navmesh_rebuilding__errors]])
