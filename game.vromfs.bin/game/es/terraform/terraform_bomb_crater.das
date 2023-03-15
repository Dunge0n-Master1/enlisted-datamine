require ecs
require ecs.safe
require ecs.common
require ecs.extra_set
require net
require app
require terraform
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require dm
require DaWeapons
require Dacoll
require RendInst
require RiDestr
require math.base
require math.interpolation
require DagorMath
require DagorSystem
require PhysMat
require Grid
require GridCollision
require enlisted.game.es.train.train_common
require enlisted.game.es.terraform.terraform_common
require EnlistedDm
require strings


enum RIPoolFlags
  None = 0
  Removable = 1
  Blocking = 2

def is_ri_pool_has_flag(handle : riex_handle_t; ri_pool_flags : IntList; flag : RIPoolFlags)
  if !riex_isRiGenExtraValid(handle)
    return false

  let poolId = handle_to_ri_type(handle)
  if poolId >= uint(length(ri_pool_flags))
    logerr("failed to check flag '{flag}' of RI pool: riName={riex_getRIGenExtraName(poolId)} poolId={int(poolId)}, length(ri_pool_flags)={length(ri_pool_flags)}, poolsCount={int(rendinst_getRiGenExtraResCount())}")
    return true

  return (ri_pool_flags[poolId] & int(flag)) == int(flag)

def can_terraform_bomb_crater_part(trace_up_height : float;
                                   trace_down_height : float;
                                   part_pos : float3;
                                   part_radius : float;
                                   railroad_half_width : float;
                                   crater_disabled_phys_mat_ids : IntList;
                                   ri_pool_flags : IntList)
  var isTerraformBlocked = false

  find_query() <| $ [es(REQUIRE=railroad__points)] ()
    let railroadPos = project_on_railroad(part_pos)
    if length_sq(railroadPos.xz - part_pos.xz) < square(part_radius + railroad_half_width)
      isTerraformBlocked = true
    return true

  if isTerraformBlocked
    return false

  // check physmat in 5 points in a current part: circle center and 4 points at edge which are form a quad
  for offsetX in range(-1, 2)
    for offsetZ in range(-1, 2)
      let pos = part_pos.xz + float2(offsetX, offsetZ) * part_radius
      let matId = dacoll_get_lmesh_mat_id_at_point(pos)
      if matId != PHYSMAT_INVALID && find_index(crater_disabled_phys_mat_ids, matId) > -1
        return false

  var queryOut = ShapeQueryOutput()
  let from = float3(part_pos.x, part_pos.y - trace_down_height, part_pos.z)
  let to = float3(part_pos.x, part_pos.y + trace_up_height, part_pos.z)
  sphere_query_ri(from, to, part_radius, queryOut, -1, null) <| $(descs : array<RendInstDesc>#)
    for desc in descs
      if is_ri_pool_has_flag(desc.riExtraHandle, ri_pool_flags, RIPoolFlags Blocking)
        isTerraformBlocked = true
        break

  if isTerraformBlocked
    return false

  find_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], BSphere3(part_pos, part_radius * 2.0), GridEntCheck POS) <| $(eid : EntityId)
    isTerraformBlocked ||= has(eid, "blockTerraform")
    return isTerraformBlocked

  return !isTerraformBlocked

def gather_ri_to_remove_in_crater_part(trace_up_height : float;
                                       trace_down_height : float;
                                       part_pos : float3;
                                       part_radius : float;
                                       ri_pool_flags : IntList;
                                       var ri_handles_to_remove : UInt64List&)
  let boxMin = float3(part_pos.x - part_radius, part_pos.y - trace_down_height, part_pos.z - part_radius)
  let boxMax = float3(part_pos.x + part_radius, part_pos.y + trace_up_height, part_pos.z + part_radius)
  gather_ri_gen_extra_collidable(BBox3(boxMin, boxMax)) <| $(handles : array<riex_handle_t>#)
    for handle in handles
      if is_ri_pool_has_flag(handle, ri_pool_flags, RIPoolFlags Removable)
        push(ri_handles_to_remove, uint64(handle))

def is_under_water(crater_pos : float2)
  var isUnderwater = false
  let hmapHeight = traceht_hmap(crater_pos)
  let pos = float3(crater_pos.x, hmapHeight, crater_pos.y)
  if !is_valid_water_height(traceht_water_at_time(pos, 0.0, get_sync_time(), isUnderwater))
    isUnderwater = false
  return isUnderwater

def foreach_available_part(bomb_crater__position : float3;
                           bomb_crater__outerRadius : float;
                           bomb_crater__partRadius : float;
                           bomb_crater__gridWidth : int;
                           bomb_crater__availablePartsMask : uint64;
                           cb : block<(part_pos : float2; part_radius : float) : void>)
  let craterPos = bomb_crater__position.xz
  let partSize = float2(bomb_crater__partRadius)
  let castPosStart = craterPos - float2(bomb_crater__outerRadius) + partSize

  var partIndex = 0ul
  for partIndexX in range(bomb_crater__gridWidth)
    for partIndexY in range(bomb_crater__gridWidth)
      let partMask = (1ul << partIndex)
      partIndex++

      if (bomb_crater__availablePartsMask & partMask) == partMask
        let partPos = castPosStart + partSize * float2(partIndexX, partIndexY) * 2.0
        invoke(cb, partPos, bomb_crater__partRadius)

def is_valid_place_for_crater(crater_pos : float3; outer_radius : float; max_height_at_land : float)
  let craterPosXZ = crater_pos.xz

  let lmeshHeight = traceht_lmesh(craterPosXZ)
  if abs(crater_pos.y - lmeshHeight) > max_height_at_land
    return false

  for offsetX in range(-1, 2)
    for offsetZ in range(-1, 2)
      if is_under_water(craterPosXZ + float2(offsetX, offsetZ) * outer_radius)
        return false

  let castPosStart = craterPosXZ - float2(outer_radius)
  let castPosEnd = craterPosXZ + float2(outer_radius)
  return is_valid_heightmap_pos(castPosStart) && is_valid_heightmap_pos(castPosEnd)


def get_ri_pool_flags(pool_id : uint;
                      is_ri_pool_removable : Object;
                      unremovable_ri_pools_by_name_part : StringList;
                      max_ri_radius_to_remove : float)
  let riName = riex_getRIGenExtraName(pool_id)

  var isBlocking = false
  for poolName in unremovable_ri_pools_by_name_part
    if find(riName, string(poolName)) > -1
      isBlocking = true

  let isPoolForcedRemovableState = get_bool(is_ri_pool_removable, riName)
  if !isBlocking && isPoolForcedRemovableState != null
    isBlocking = !*isPoolForcedRemovableState

  if !isBlocking && (riex_isWalls(pool_id) || riex_isImmortal(pool_id))
    isBlocking = true

  if !isBlocking
    let isInRadius = riex_getBsphRad(pool_id) <= max_ri_radius_to_remove
    let parentForDestroyedRiIdx = riex_getParentForDestroyedRiIdx(pool_id)
    let isDestroyedPhysResExist = riex_isDestroyedPhysResExist(pool_id)
    if !isInRadius && parentForDestroyedRiIdx < 0 && !isDestroyedPhysResExist
      isBlocking = true

  let isRemovable = !isBlocking && !riex_isDestroyedPhysResExist(pool_id) || isPoolForcedRemovableState ?? false

  return int(isBlocking ? RIPoolFlags Blocking
           : isRemovable ? RIPoolFlags Removable
           : RIPoolFlags None)


def calc_main_physmat_in_crater(crater_pos : float3; outer_radius : float)
  var physmats : table<int; int>

  for offset in [[float2 float2(0, 0); float2(0, 1); float2(0, -1); float2(-1, 0); float2(1, 0)]]
    let posXZ = crater_pos.xz + offset * outer_radius
    let matId = dacoll_get_lmesh_mat_id_at_point(posXZ)
    if matId != -1
      physmats[matId]++

  var mainMatId = -1
  var maxPhysMatsCount = 0
  for physmatId, physmatCount in keys(physmats), values(physmats)
    if physmatCount > maxPhysMatsCount
      maxPhysMatsCount = physmatCount
      mainMatId = physmatId

  return mainMatId


def get_crater_scale_by_main_physmat_in_crater(main_mat_id : int;  crater_config__scaleByPhysmats : Object)
  let defScale = float4(1.0)
  if main_mat_id < 0
    return defScale

  let mainMatName = get_material_name(get_material(main_mat_id))
  let craterScaleForMat = crater_config__scaleByPhysmats[mainMatName] ?? defScale
  return craterScaleForMat


[es(tag=server, on_appear)]
def terraform_crater_init_disabled_phys_mats(evt : Event; crater_config__disabledPhysMatNames : StringList; var crater_config__disabledPhysMatIds : IntList&)
  clear(crater_config__disabledPhysMatIds)
  for matName in crater_config__disabledPhysMatNames
    let matId = get_material_id(string(matName))
    if matId != PHYSMAT_INVALID
      push(crater_config__disabledPhysMatIds, matId)
    else
      logerr("invalid physmat name '{matName}' in crater_config__disabledPhysMatNames")


[es(tag=server, on_event=(EventLevelLoaded, CmdUpdateBombCraterRiPoolFlags), after=terraform_crater_init_ri_pool_flags)]
def terraform_crater_update_ri_pool_flags(evt : Event;
                                          crater_config__isRIPoolRemovable : Object;
                                          crater_config__unremovableRIPoolsByNamePart : StringList;
                                          crater_config__maxRIRadiusToRemove : float;
                                          var crater_config__riPoolFlags : IntList&)
  let riPoolFlagsLen = length(crater_config__riPoolFlags)
  let poolsCount = int(rendinst_getRiGenExtraResCount())
  if riPoolFlagsLen >= poolsCount
    return

  resize(crater_config__riPoolFlags, poolsCount)

  for i in range(riPoolFlagsLen, poolsCount)
    crater_config__riPoolFlags[i] = get_ri_pool_flags(uint(i),
                                                             crater_config__isRIPoolRemovable,
                                                             crater_config__unremovableRIPoolsByNamePart,
                                                             crater_config__maxRIRadiusToRemove)


[es(tag=server, REQUIRE=shouldCreateBulletCrater)]
def terraform_crater_on_projectile_explosion(evt : EventShellExplodedServer;
                                             launch_desc : LaunchDesc)
  query() <| $ [es] (bullet_crater_config__innerRadiusScale : float;
                     bullet_crater_config__outerRadiusScale : float;
                     bullet_crater_config__innerDepthScale : float;
                     bullet_crater_config__outerAltScale : float;
                     bullet_crater_config__maxHeightAtLand : float;
                     bullet_crater_config__explosiveMassToCraterRadius : Point2List;
                     crater_config__scaleByPhysmats : Object)
    let bulletCraterExplosiveMassToCraterRadiusLen = length(bullet_crater_config__explosiveMassToCraterRadius)
    if bulletCraterExplosiveMassToCraterRadiusLen < 1
      return

    let explosiveMass = explosive_get_props(int(launch_desc.shellId.damageId))?.mass ?? 0.0
    if explosiveMass < bullet_crater_config__explosiveMassToCraterRadius[0].x
      return
    if explosiveMass > bullet_crater_config__explosiveMassToCraterRadius[bulletCraterExplosiveMassToCraterRadiusLen - 1].x
      return

    let position = evt.pos
    let outerRadius = interpolate_by_point_list(bullet_crater_config__explosiveMassToCraterRadius, explosiveMass) * bullet_crater_config__outerRadiusScale

    if is_valid_place_for_crater(position, outerRadius, bullet_crater_config__maxHeightAtLand)
      let innerRadius = outerRadius * bullet_crater_config__innerRadiusScale
      let innerDepth = -outerRadius * bullet_crater_config__innerDepthScale
      let outerAlt = outerRadius * bullet_crater_config__outerAltScale

      let mainMatId = calc_main_physmat_in_crater(position, outerRadius)
      let craterScaleForMat = get_crater_scale_by_main_physmat_in_crater(mainMatId, crater_config__scaleByPhysmats)

      let eid = createEntity("bomb_crater_terraformer") <| $(var init : ComponentsInitializer)
        set(init, "bomb_crater_terraformer__position", position)
        set(init, "bomb_crater_terraformer__innerRadius", innerRadius * craterScaleForMat.x)
        set(init, "bomb_crater_terraformer__innerDepth",  innerDepth  * craterScaleForMat.y)
        set(init, "bomb_crater_terraformer__outerRadius", outerRadius * craterScaleForMat.z)
        set(init, "bomb_crater_terraformer__outerAlt",    outerAlt    * craterScaleForMat.w)
        set(init, "bomb_crater_terraformer__mainPhysmatId", mainMatId)

[es(tag=server, REQUIRE=shouldCreateCrater)]
def terraform_crater_on_bomb_explosion(evt : EventShellExplodedServer;
                                       launch_desc : LaunchDesc)
  query() <| $ [es] (bomb_crater_config__innerRadiusScale : float;
                     bomb_crater_config__outerRadiusScale : float;
                     bomb_crater_config__innerDepthScale : float;
                     bomb_crater_config__outerAltScale : float;
                     bomb_crater_config__maxHeightAtLand : float;
                     bomb_crater_config__splashToCraterRadius : Point2List;
                     crater_config__scaleByPhysmats : Object)
    using() <| $(var splashParams : SplashParams#)
      splashParams = calc_splash_params(int(launch_desc.shellId.shellId), false)

      let position = evt.pos
      let outerRadius = interpolate_by_point_list(bomb_crater_config__splashToCraterRadius, splashParams.outerRadius) * bomb_crater_config__outerRadiusScale

      if is_valid_place_for_crater(position, outerRadius, bomb_crater_config__maxHeightAtLand)
        let innerRadius = outerRadius * bomb_crater_config__innerRadiusScale
        let innerDepth = -outerRadius * bomb_crater_config__innerDepthScale
        let outerAlt = outerRadius * bomb_crater_config__outerAltScale

        let mainMatId = calc_main_physmat_in_crater(position, outerRadius)
        let craterScaleForMat = get_crater_scale_by_main_physmat_in_crater(mainMatId, crater_config__scaleByPhysmats)

        let eid = createEntity("bomb_crater_terraformer") <| $(var init : ComponentsInitializer)
          set(init, "bomb_crater_terraformer__position", position)
          set(init, "bomb_crater_terraformer__innerRadius", innerRadius * craterScaleForMat.x)
          set(init, "bomb_crater_terraformer__innerDepth",  innerDepth  * craterScaleForMat.y)
          set(init, "bomb_crater_terraformer__outerRadius", outerRadius * craterScaleForMat.z)
          set(init, "bomb_crater_terraformer__outerAlt",    outerAlt    * craterScaleForMat.w)
          set(init, "bomb_crater_terraformer__mainPhysmatId", mainMatId)

[es(tag=server, on_appear)]
def bomb_crater_terraformer_on_init(evt : Event;
                                    eid : EntityId;
                                    bomb_crater_terraformer__gridWidth : int;
                                    bomb_crater_terraformer__expectedRiHandlesToRemoveCount : int;
                                    var bomb_crater_terraformer__riHandlesToRemove : UInt64List&)
  let MAX_CRATER_PARTS_COUNT_IN_UINT64_BITMASK = 8 // 8 because 8*8=64 - bits count in uint64

  if bomb_crater_terraformer__gridWidth <= 0 || bomb_crater_terraformer__gridWidth > MAX_CRATER_PARTS_COUNT_IN_UINT64_BITMASK
    logerr("invalid gridWidth in bomb_crater_terraformer: {bomb_crater_terraformer__gridWidth}")
    destroyEntity(eid)
    return

  if bomb_crater_terraformer__expectedRiHandlesToRemoveCount > 0
    reserve(bomb_crater_terraformer__riHandlesToRemove, bomb_crater_terraformer__expectedRiHandlesToRemoveCount)

  query() <| $ [es] (crater_config__riPoolFlags : IntList)
    if length(crater_config__riPoolFlags) < int(rendinst_getRiGenExtraResCount())
      broadcastEventImmediate([[CmdUpdateBombCraterRiPoolFlags]])

def process_bomb_crater_terraformer(crater_config__disabledPhysMatIds : IntList;
                                    crater_config__riPoolFlags : IntList;
                                    eid : EntityId;
                                    bomb_crater_terraformer__processPartsPerFrame : int;
                                    bomb_crater_terraformer__gridWidth : int;
                                    bomb_crater_terraformer__railroadHalfWidth : float;
                                    bomb_crater_terraformer__position : float3;
                                    bomb_crater_terraformer__innerRadius : float;
                                    bomb_crater_terraformer__innerDepth : float;
                                    bomb_crater_terraformer__outerAlt : float;
                                    bomb_crater_terraformer__outerRadius : float;
                                    bomb_crater_terraformer__mainPhysmatId : int;
                                    var bomb_crater_terraformer__processedPartsCount : int&;
                                    var bomb_crater_terraformer__availablePartsMask : uint64&;
                                    var bomb_crater_terraformer__riHandlesToRemove : UInt64List&)
  let outerRadius = bomb_crater_terraformer__outerRadius
  let partRadius = outerRadius / float(bomb_crater_terraformer__gridWidth)

  // gridWidth is side of quad of bomb crater outer radius measured in diameters of small tracing spheres
  // gridWidth^2 is area of bomb crater outer radius quad and total count of tracing spheres
  if bomb_crater_terraformer__processedPartsCount >= square(bomb_crater_terraformer__gridWidth)
    var ri_handles_to_remove : array<uint64>
    reserve(ri_handles_to_remove, length(bomb_crater_terraformer__riHandlesToRemove))

    for handle in bomb_crater_terraformer__riHandlesToRemove
      if find_index(ri_handles_to_remove, handle) < 0
        push(ri_handles_to_remove, handle)

    let craterEid = createEntity("bomb_crater") <| $(var init : ComponentsInitializer)
      set(init, "bomb_crater__position", bomb_crater_terraformer__position)
      set(init, "bomb_crater__innerRadius", bomb_crater_terraformer__innerRadius)
      set(init, "bomb_crater__innerDepth", bomb_crater_terraformer__innerDepth)
      set(init, "bomb_crater__outerRadius", bomb_crater_terraformer__outerRadius)
      set(init, "bomb_crater__outerAlt", bomb_crater_terraformer__outerAlt)
      set(init, "bomb_crater__partRadius", partRadius)
      set(init, "bomb_crater__availablePartsMask", bomb_crater_terraformer__availablePartsMask)
      set(init, "bomb_crater__gridWidth", bomb_crater_terraformer__gridWidth)
      set(init, "bomb_crater__riHandlesToRemove", ri_handles_to_remove)
      set(init, "bomb_crater__mainPhysmatId", bomb_crater_terraformer__mainPhysmatId)
    destroyEntity(eid)
    return

  let partSize = float2(partRadius)
  let castPosStart = bomb_crater_terraformer__position.xz - float2(outerRadius) + partSize

  let processedPartsCount = bomb_crater_terraformer__processedPartsCount
  let startPartIndexX = processedPartsCount / bomb_crater_terraformer__gridWidth
  var startPartIndexY = processedPartsCount % bomb_crater_terraformer__gridWidth

  for partIndexX in range(startPartIndexX, bomb_crater_terraformer__gridWidth)
    for partIndexY in range(startPartIndexY, bomb_crater_terraformer__gridWidth)
      // We go through the parts of the craters gradually. Line by line. For example,
      // in the previous frame we stopped in the middle of the line - we reached the limit.
      // We remembered this and went to the next frame. There we continued from the old place
      // on the line and reached its end. We are moved to the next *still unprocessed* line.
      // Naturally, we need to process this new line from the very beginning, and therefore we
      // need to reset the index of the tracing sphere on this line to the initial value - 0
      startPartIndexY = 0

      if (bomb_crater_terraformer__processedPartsCount - processedPartsCount) >= bomb_crater_terraformer__processPartsPerFrame
        return

      let partPosXZ = castPosStart + partSize * float2(partIndexX, partIndexY) * 2.0

      let hmapHeight = traceht_hmap(partPosXZ)
      if hmapHeight > -1e5f
        let partPos = float3(partPosXZ.x, min(bomb_crater_terraformer__position.y, hmapHeight), partPosXZ.y)
        if can_terraform_bomb_crater_part(bomb_crater_terraformer__outerAlt,
                                          -bomb_crater_terraformer__innerDepth,
                                          partPos,
                                          partRadius,
                                          bomb_crater_terraformer__railroadHalfWidth,
                                          crater_config__disabledPhysMatIds,
                                          crater_config__riPoolFlags)
          let partMask = (1ul << uint64(bomb_crater_terraformer__processedPartsCount))
          bomb_crater_terraformer__availablePartsMask |= partMask

          gather_ri_to_remove_in_crater_part(bomb_crater_terraformer__outerAlt,
                                              -bomb_crater_terraformer__innerDepth,
                                              partPos,
                                              partRadius,
                                              crater_config__riPoolFlags,
                                              bomb_crater_terraformer__riHandlesToRemove)

      bomb_crater_terraformer__processedPartsCount++

[es(tag=server, no_order)]
def bomb_crater_terraformer_update(info : UpdateStageInfoAct; crater_config__disabledPhysMatIds : IntList; crater_config__riPoolFlags : IntList)
  find_query() <| $ [es] (eid : EntityId;
                          bomb_crater_terraformer__processPartsPerFrame : int;
                          bomb_crater_terraformer__gridWidth : int;
                          bomb_crater_terraformer__railroadHalfWidth : float;
                          bomb_crater_terraformer__position : float3;
                          bomb_crater_terraformer__innerRadius : float;
                          bomb_crater_terraformer__innerDepth : float;
                          bomb_crater_terraformer__outerAlt : float;
                          bomb_crater_terraformer__outerRadius : float;
                          bomb_crater_terraformer__mainPhysmatId : int;
                          var bomb_crater_terraformer__processedPartsCount : int&;
                          var bomb_crater_terraformer__availablePartsMask : uint64&;
                          var bomb_crater_terraformer__riHandlesToRemove : UInt64List&)
    process_bomb_crater_terraformer(crater_config__disabledPhysMatIds,
                                    crater_config__riPoolFlags,
                                    eid,
                                    bomb_crater_terraformer__processPartsPerFrame,
                                    bomb_crater_terraformer__gridWidth,
                                    bomb_crater_terraformer__railroadHalfWidth,
                                    bomb_crater_terraformer__position,
                                    bomb_crater_terraformer__innerRadius,
                                    bomb_crater_terraformer__innerDepth,
                                    bomb_crater_terraformer__outerAlt,
                                    bomb_crater_terraformer__outerRadius,
                                    bomb_crater_terraformer__mainPhysmatId,
                                    bomb_crater_terraformer__processedPartsCount,
                                    bomb_crater_terraformer__availablePartsMask,
                                    bomb_crater_terraformer__riHandlesToRemove)
    return true

def bomb_crater_apply(bomb_crater__position : float3;
                      bomb_crater__innerRadius : float;
                      bomb_crater__innerDepth : float;
                      bomb_crater__outerRadius : float;
                      bomb_crater__outerAlt : float;
                      bomb_crater__partRadius : float;
                      bomb_crater__availablePartsMask : uint64;
                      bomb_crater__gridWidth : int;
                      bomb_crater__riHandlesToRemove : UInt64List;
                      bomb_crater__destroyRiCountPerFrame : int;
                      bomb_crater__mainPhysmatId : int;
                      var bomb_crater__riHandlesRemovedCount : int&;
                      var bomb_crater__isTerraformed : bool&;
                      var terraform : TerraformComponent)
  if !bomb_crater__isTerraformed
    bomb_crater__isTerraformed = true

    let craterPos = bomb_crater__position.xz
    foreach_available_part(bomb_crater__position,
                          bomb_crater__outerRadius,
                          bomb_crater__partRadius,
                          bomb_crater__gridWidth,
                          bomb_crater__availablePartsMask) <| $(part_pos : float2; part_radius : float)
      terraform |> terraform_makeBombCraterPart(craterPos,
                                                bomb_crater__innerRadius,
                                                bomb_crater__innerDepth,
                                                bomb_crater__outerRadius,
                                                bomb_crater__outerAlt,
                                                part_pos,
                                                part_radius)

      broadcastEvent([[EventBombCraterPartTerraformed
        partPos=float3(part_pos.x, bomb_crater__position.y, part_pos.y),
        partRadius=part_radius
      ]])
  else
    let lastRemovedCount = bomb_crater__riHandlesRemovedCount

    for i in range(lastRemovedCount, length(bomb_crater__riHandlesToRemove))
      let handle = bomb_crater__riHandlesToRemove[i]

      if riex_isRiGenExtraValid(handle)
        var out_desc = RendInstDesc()
        destroyRendinst(RendInstDesc(handle), out_desc)
        rendinst_delRIGenExtra(out_desc.riExtraHandle)

      bomb_crater__riHandlesRemovedCount++
      if (bomb_crater__riHandlesRemovedCount - lastRemovedCount) >= bomb_crater__destroyRiCountPerFrame
        break

  let isApplyingCompleted = bomb_crater__isTerraformed && bomb_crater__riHandlesRemovedCount == length(bomb_crater__riHandlesToRemove)
  if isApplyingCompleted && bomb_crater__availablePartsMask != uint64(0)
    broadcastEvent([[EventBombCraterTerraformed
      pos=bomb_crater__position,
      outerRadius=bomb_crater__outerRadius,
      availablePartsMask=bomb_crater__availablePartsMask,
      partsGridWidth=bomb_crater__gridWidth,
      mainPhysmatId=bomb_crater__mainPhysmatId
    ]])

  return isApplyingCompleted

[es(tag=server, before=terraform_update_es)]
def bomb_crater_apply_server_es(info : UpdateStageInfoAct; var terraform : TerraformComponent)
  find_query() <| $ [es(REQUIRE_NOT=bombCraterAppliedServer)] (eid : EntityId;
                                                               bomb_crater__removeRiCountPerFrame : int;
                                                               bomb_crater__position : float3;
                                                               bomb_crater__innerRadius : float;
                                                               bomb_crater__innerDepth : float;
                                                               bomb_crater__outerRadius : float;
                                                               bomb_crater__outerAlt : float;
                                                               bomb_crater__partRadius : float;
                                                               bomb_crater__availablePartsMask : uint64;
                                                               bomb_crater__gridWidth : int;
                                                               bomb_crater__riHandlesToRemove : UInt64List;
                                                               bomb_crater__mainPhysmatId : int;
                                                               var bomb_crater__riHandlesRemovedCount : int&;
                                                               var bomb_crater__isTerraformed : bool&)
    if bomb_crater_apply(bomb_crater__position, bomb_crater__innerRadius, bomb_crater__innerDepth,
                         bomb_crater__outerRadius, bomb_crater__outerAlt, bomb_crater__partRadius,
                         bomb_crater__availablePartsMask, bomb_crater__gridWidth, bomb_crater__riHandlesToRemove,
                         bomb_crater__removeRiCountPerFrame,
                         bomb_crater__mainPhysmatId,
                         bomb_crater__riHandlesRemovedCount,
                         bomb_crater__isTerraformed,
                         terraform)
      addSubTemplate(eid, "bomb_crater_applied_server")
      print("bomb_crater applied: eid={eid} position={bomb_crater__position} outerRadius={bomb_crater__outerRadius} availablePartsMask={bomb_crater__availablePartsMask} riHandlesRemovedCount={bomb_crater__riHandlesRemovedCount}")
    return true

[es(tag=netClient, before=terraform_update_es)]
def bomb_crater_apply_client_es(info : UpdateStageInfoAct; var terraform : TerraformComponent)
  find_query() <| $ [es(REQUIRE_NOT=bombCraterAppliedClient)] (eid : EntityId;
                                                               bomb_crater__removeRiCountPerFrame : int;
                                                               bomb_crater__position : float3;
                                                               bomb_crater__innerRadius : float;
                                                               bomb_crater__innerDepth : float;
                                                               bomb_crater__outerRadius : float;
                                                               bomb_crater__outerAlt : float;
                                                               bomb_crater__partRadius : float;
                                                               bomb_crater__availablePartsMask : uint64;
                                                               bomb_crater__gridWidth : int;
                                                               bomb_crater__riHandlesToRemove : UInt64List;
                                                               bomb_crater__mainPhysmatId : int;
                                                               var bomb_crater__riHandlesRemovedCount : int&;
                                                               var bomb_crater__isTerraformed : bool&)
    if bomb_crater_apply(bomb_crater__position, bomb_crater__innerRadius, bomb_crater__innerDepth,
                         bomb_crater__outerRadius, bomb_crater__outerAlt, bomb_crater__partRadius,
                         bomb_crater__availablePartsMask, bomb_crater__gridWidth, bomb_crater__riHandlesToRemove,
                         bomb_crater__removeRiCountPerFrame,
                         bomb_crater__mainPhysmatId,
                         bomb_crater__riHandlesRemovedCount,
                         bomb_crater__isTerraformed,
                         terraform)
      addSubTemplate(eid, "bomb_crater_applied_client")
    return true

[es]
def bomb_crater_part_on_damage_rigen(evt : EventBombCraterTerraformed)
  let sphere = BSphere3(evt.pos, ceil(evt.outerRadius))
  let axis : float3
  rendinst_doRIGenDamage(sphere, get_dagor_frame_no(), axis)

[es(tag=server)]
def clean_loot_on_terraform_bomb_crater(evt : EventBombCraterTerraformed)
  clean_loot_in_radius(evt.pos, evt.outerRadius)
