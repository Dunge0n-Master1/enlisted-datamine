require ecs
require Dacoll
require CollRes
require math.base
require DagorMath
require game.events_game
require game.es.voxel.voxel_grid_common

let
  X_AXIS = 0
  Y_AXIS = 1
  Z_AXIS = 2

def init_voxels(transform : float3x4;
                voxel_grid__step : float;
                voxel_grid__resolution : int;
                voxel_grid__minCollnodeRadius : float;
                var voxel_grid__voxels : BoolList&)
  let gridLen = voxel_grid__resolution * voxel_grid__resolution * voxel_grid__resolution
  voxel_grid__voxels |> resize(gridLen)
  for voxel in voxel_grid__voxels
    voxel = true

  let invVoxelSize = safeinv(voxel_grid__step)
  let center = transform[3]
  let voxelBoxHalf = float(voxel_grid__resolution) * voxel_grid__step * 0.5
  let voxelBbox = BBox3(center - float3(voxelBoxHalf), center + float3(voxelBoxHalf))
  let voxelLocalBase = (center - float3(voxelBoxHalf)) * -invVoxelSize

  gather_ri_gen_extra_collidable(voxelBbox) <| $(handles : array<riex_handle_t>#)
    for handle in handles
      using(handle) <| $(var desc : RendInstDesc#)
        if !desc.isValid
          return
        let collres = getRiGenCollisionResource(desc)
        if collres == null
          return

        let nodesCnt = (*collres) |> collres_get_nodesCount()
        let rootTm = getRIGenMatrix(desc)

        for i in range(nodesCnt)
          let node = (*collres) |> collres_get_node(i)
          var nodeTm : float3x4
          collres_get_collision_node_tm(*collres, i, rootTm, null, nodeTm)
          var start_triangle = 0
          var max_triangles = -1
          rasterize_collnode(node, nodeTm, voxelBbox, voxelLocalBase, invVoxelSize, voxel_grid__minCollnodeRadius, voxel_grid__resolution,
                             start_triangle, max_triangles, voxel_grid__voxels)

def check_grid_connectivity(transform : float3x4;
                            voxel_grid__step : float;
                            voxel_grid__resolution : int;
                            var voxel_grid__voxels : BoolList&)
  let count = length(voxel_grid__voxels)
  var open : array<bool>
  open |> resize(count)
  var queue : array<tuple<pos : int3; index : int>>

  let dirs = [[tuple<stepPos : int3; stepIndex : int>
    [[auto int3(-1, 0, 0),-1]];
    [[auto int3(+1, 0, 0), +1]];
    [[auto int3(0,-1, 0),-voxel_grid__resolution]];
    [[auto int3(0, +1, 0), +voxel_grid__resolution]];
    [[auto int3(0, 0,-1),-voxel_grid__resolution * voxel_grid__resolution]];
    [[auto int3(0, 0, +1), +voxel_grid__resolution * voxel_grid__resolution]];
  ]]

  if voxel_grid__resolution % 2 == 0 // Even grid, start point is between 8 voxels
    let centerRight = voxel_grid__resolution / 2
    let centerLeft = centerRight - 1
    for x in range(centerLeft, centerRight + 1)
      for y in range(centerLeft, centerRight + 1)
        for z in range(centerLeft, centerRight + 1)
          let startPos = int3(x, y, z)
          let start = get_voxel_index(startPos, voxel_grid__resolution)
          if start < count && voxel_grid__voxels[start]
            queue |> emplace([[auto startPos, start]])
            open[start] = true
  else // Odd grid with single voxel in center
    let start = get_voxel_index(transform, transform[3], voxel_grid__resolution, voxel_grid__step)
    queue |> emplace([[auto get_voxel_pos(start, voxel_grid__resolution), start]])
    open[start] = true

  using() <| $(var result : BoolList)
    result |> resize(count)
    var queueIndex = 0
    while queueIndex < length(queue)
      let from = queue[queueIndex]
      queueIndex++
      result[from.index] = true
      for dir in dirs
        let toPos = clamp(from.pos + dir.stepPos, int3(), int3(voxel_grid__resolution - 1))
        let toInd = from.index + dir.stepIndex
        if toPos == from.pos || toInd < 0 || toInd >= count || !voxel_grid__voxels[toInd] || result[toInd] || open[toInd]
          continue
        queue |> emplace([[auto toPos, toInd]])
        open[toInd] = true
    voxel_grid__voxels := result

def rasterize_edge_impl(axis : int;
                        a : float3;
                        b : float3;
                        main_dir : float3;
                        var from_idx : int;
                        var to_idx : int;
                        var buffer : array<float3>&)
  let ai = floori(a[axis])
  let bi = floori(b[axis])
  to_idx = min(bi, to_idx)
  from_idx = max(ai, from_idx)

  if ai == bi
    return

  let dp = b - a
  let step = dp * safeinv(dp[axis])
  var offset = (float(from_idx) + 0.5 - a[axis]) * step + a

  for i in range(from_idx, to_idx + 1)
    buffer[i] = offset
    offset += step

  if from_idx <= ai && ai <= to_idx && a[axis] > float(ai) + 0.5
    buffer[ai] = calc_edge_point(axis, ai, a, main_dir)
  if from_idx <= bi && bi <= to_idx && b[axis] < float(bi) + 0.5
    buffer[bi] = calc_edge_point(axis, bi, b, main_dir)

def rasterize_edge(axis : int;
                   a : float3;
                   b : float3;
                   main_dir : float3;
                   from_idx : int;
                   to_idx : int;
                   var left_edge_buffer : array<float3>&;
                   var right_edge_buffer : array<float3>&)
  if a[axis] > b[axis]
    rasterize_edge_impl(axis, b, a, main_dir, from_idx, to_idx, left_edge_buffer)
  else
    rasterize_edge_impl(axis, a, b, main_dir, from_idx, to_idx, right_edge_buffer)

def calc_edge_point(axis : int;
                    idx : int;
                    p : float3;
                    dir : float3)
  return (float(idx) + 0.5 - p[axis]) * dir + p

def set_voxel(pos : int3; resolution : int; var voxels : BoolList&)
  voxels[get_voxel_index(pos, resolution)] = false

def rasterize_triangle_impl(resolution : int;
                            var bbox0 : int3;
                            var bbox1 : int3;
                            p0 : float3;
                            p1 : float3;
                            p2 : float3;
                            norm : float3;
                            main_axis : int;
                            secondary_axis : int;
                            third_axis : int;
                            var voxels : BoolList&)
  // Rasterizer
  var left_edge_buffer : array<float3>
  var right_edge_buffer : array<float3>
  left_edge_buffer |> resize(resolution * 2)
  right_edge_buffer |> resize(resolution * 2)

  if (bbox1[main_axis] < 0 || bbox0[main_axis] >= resolution ||
      bbox1[secondary_axis] < 0 || bbox0[secondary_axis] >= resolution ||
      bbox1[third_axis] < 0 || bbox0[third_axis] >= resolution)
    return false

  var mainDir : float3
  mainDir[main_axis] = norm[third_axis]
  mainDir[secondary_axis] = -norm[main_axis]
  mainDir[third_axis] = 0.0

  mainDir *= safeinv(norm[third_axis])

  if bbox0[main_axis] != bbox1[main_axis]
    bbox0[main_axis] = max(0, bbox0[main_axis])
    bbox1[main_axis] = min(resolution - 1, bbox1[main_axis])
    rasterize_edge(main_axis, p0, p1, mainDir, bbox0[main_axis], bbox1[main_axis], left_edge_buffer, right_edge_buffer)
    rasterize_edge(main_axis, p1, p2, mainDir, bbox0[main_axis], bbox1[main_axis], left_edge_buffer, right_edge_buffer)
    rasterize_edge(main_axis, p2, p0, mainDir, bbox0[main_axis], bbox1[main_axis], left_edge_buffer, right_edge_buffer)
  else
    let idx = bbox0[main_axis]
    var edgePoints : array<float3>
    edgePoints |> push(calc_edge_point(main_axis, idx, p0, mainDir))
    edgePoints |> push(calc_edge_point(main_axis, idx, p1, mainDir))
    edgePoints |> push(calc_edge_point(main_axis, idx, p2, mainDir))
    sort(edgePoints) <| $(l, r : float3) => l[secondary_axis] < r[secondary_axis]
    left_edge_buffer[idx] = edgePoints[0]
    right_edge_buffer[idx] = edgePoints[2]

  let aiMin = 0
  let biMax = resolution - 1
  let res = float(resolution) - 0.0001

  for i in range(bbox0[main_axis], bbox1[main_axis] + 1)
    var va = left_edge_buffer[i]
    var vb = right_edge_buffer[i]
    let d = vb - va


    if d[secondary_axis] < 0.0
      swap(va, vb)

    let ai = max(floori(va), int3(aiMin))
    let bi = min(floori(vb), int3(biMax))
    var a = ai[secondary_axis]
    var b = bi[secondary_axis]

    if a > b
      continue

    let step = d * safeinv(d[secondary_axis])
    var offset = (float(a) + 0.5 - va[secondary_axis]) * step + va

    if offset[third_axis] < 0. || offset[third_axis] > res
      var t = ((offset[third_axis] > 0. ? res : 0.) - offset[third_axis]) * safeinv(step[third_axis])
      if t > 0. && step[third_axis] > 0. && a < b
        t = ceil(t)
        offset += step * t
        a += int(t)

        if a > b
          continue

    var p = offset

    let last = b + 1
    for j in range(a, last)
      b = j
      let pi = int3(p)
      p += step
      let zi = pi[third_axis]
      if zi >= 0 && zi < resolution
        set_voxel(pi, resolution, voxels)
  return true

def rasterize_triangle(p0 : float3;
                       p1 : float3;
                       p2 : float3;
                       resolution : int;
                       var voxels : BoolList&)
  let pi0 = floori(p0)
  let pi1 = floori(p1)
  let pi2 = floori(p2)
  let bbox0 = min(min(pi0, pi1), pi2)
  let bbox1 = max(max(pi0, pi1), pi2)

  let norm = cross(p1 - p0, p2 - p1)
  let normAbs = abs(norm)

  if normAbs.x <= normAbs.y && normAbs.x <= normAbs.z
    if normAbs.y <= normAbs.z
      return rasterize_triangle_impl(resolution, bbox0, bbox1, p0, p1, p2, norm, X_AXIS, Y_AXIS, Z_AXIS, voxels)
    else
      return rasterize_triangle_impl(resolution, bbox0, bbox1, p0, p1, p2, norm, X_AXIS, Z_AXIS, Y_AXIS, voxels)
  elif normAbs.y <= normAbs.x && normAbs.y <= normAbs.z
    if normAbs.x <= normAbs.z
      return rasterize_triangle_impl(resolution, bbox0, bbox1, p0, p1, p2, norm, Y_AXIS, X_AXIS, Z_AXIS, voxels)
    else
      return rasterize_triangle_impl(resolution, bbox0, bbox1, p0, p1, p2, norm, Y_AXIS, Z_AXIS, X_AXIS, voxels)
  elif normAbs.z <= normAbs.x && normAbs.z <= normAbs.y
    if normAbs.x <= normAbs.y
      return rasterize_triangle_impl(resolution, bbox0, bbox1, p0, p1, p2, norm, Z_AXIS, X_AXIS, Y_AXIS, voxels)
    else
      return rasterize_triangle_impl(resolution, bbox0, bbox1, p0, p1, p2, norm, Z_AXIS, Y_AXIS, X_AXIS, voxels)
  return false

def rasterize_collnode(node : CollisionNode const?;
                       node_tm : float3x4;
                       voxel_bbox : BBox3;
                       voxel_local_base : float3;
                       voxel_size_inv : float;
                       min_collnode_radius : float;
                       resolution : int;
                       var current_triangle : int&;
                       var triangles_to_process : int&;
                       var voxels : BoolList&)
  if (uint(node.behaviorFlags) & uint(BehaviorFlag PHYS_COLLIDABLE)) == 0u
    return true
  if (node.boundingSphere.r < min_collnode_radius) || !(voxel_bbox & (node_tm * node.modelBBox))
    return true

  var isFinished = true

  let nodeType = int(node.nodeType)
  if nodeType == int(CollisionResourceNodeType COLLISION_NODE_TYPE_MESH) || nodeType == int(CollisionResourceNodeType COLLISION_NODE_TYPE_CONVEX)
    get_collnode_geom(node) <| $(indices; vertices)
      let numTriangles = length(indices) / 3

      while current_triangle < numTriangles && triangles_to_process != 0
        var p0 = vertices[int(indices[current_triangle * 3 + 0])].xyz
        var p1 = vertices[int(indices[current_triangle * 3 + 1])].xyz
        var p2 = vertices[int(indices[current_triangle * 3 + 2])].xyz
        p0 = node_tm * p0
        p1 = node_tm * p1
        p2 = node_tm * p2
        let vp0 = p0 * voxel_size_inv + voxel_local_base
        let vp1 = p1 * voxel_size_inv + voxel_local_base
        let vp2 = p2 * voxel_size_inv + voxel_local_base
        if rasterize_triangle(vp0, vp1, vp2, resolution, voxels) && triangles_to_process > 0
          triangles_to_process--
        current_triangle++
      isFinished = current_triangle >= numTriangles
  elif nodeType == int(CollisionResourceNodeType COLLISION_NODE_TYPE_BOX)
    let boxMin = node.modelBBox.boxMin
    let boxMax = node.modelBBox.boxMax
    let points = [[float3
                   node_tm * boxMin * voxel_size_inv + voxel_local_base;
                   node_tm * float3(boxMin.x, boxMin.y, boxMax.z) * voxel_size_inv + voxel_local_base;
                   node_tm * float3(boxMin.x, boxMax.y, boxMin.z) * voxel_size_inv + voxel_local_base;
                   node_tm * float3(boxMin.x, boxMax.y, boxMax.z) * voxel_size_inv + voxel_local_base;
                   node_tm * float3(boxMax.x, boxMin.y, boxMin.z) * voxel_size_inv + voxel_local_base;
                   node_tm * float3(boxMax.x, boxMin.y, boxMax.z) * voxel_size_inv + voxel_local_base;
                   node_tm * float3(boxMax.x, boxMax.y, boxMin.z) * voxel_size_inv + voxel_local_base;
                   node_tm * boxMax * voxel_size_inv + voxel_local_base
                 ]]
    for side in [[int4
                  int4(0, 1, 2, 3);
                  int4(4, 5, 6, 7);
                  int4(0, 2, 4, 6);
                  int4(1, 3, 5, 7);
                  int4(0, 1, 4, 5);
                  int4(2, 3, 6, 7);
                ]]
      // TODO: could be done better
      rasterize_triangle(points[side[0]], points[side[1]], points[side[2]], resolution, voxels)
      rasterize_triangle(points[side[1]], points[side[2]], points[side[3]], resolution, voxels)
    triangles_to_process -= 12
  // TODO: other collnode types

  return isFinished

def rasterize_rendinst(handle : uint64;
                       voxel_bbox : BBox3;
                       voxel_local_base : float3;
                       voxel_size_inv : float;
                       min_collnode_radius : float;
                       resolution : int;
                       var current_collnode : int&;
                       var current_triangle : int&;
                       var triangles_to_process : int&;
                       var voxels : BoolList&)
  var isFinished = true
  using(handle) <| $(var desc : RendInstDesc#)
    let collres = getRiGenCollisionResource(desc)
    let nodesCnt = (*collres) |> collres_get_nodesCount()
    let rootTm = getRIGenMatrix(desc)

    for i in range(current_collnode, nodesCnt)
      let node = (*collres) |> collres_get_node(i)
      var nodeTm : float3x4
      collres_get_collision_node_tm(*collres, i, rootTm, null, nodeTm)
      if !rasterize_collnode(node, nodeTm, voxel_bbox, voxel_local_base, voxel_size_inv, min_collnode_radius, resolution,
                            current_triangle, triangles_to_process, voxels)
        break // collnode not finished
      current_collnode++
      current_triangle = 0
    isFinished = current_collnode >= nodesCnt

  return isFinished

def gather_ri_extras(bbox : BBox3; var out_list : UInt64List&)
  gather_ri_gen_extra_collidable(bbox) <| $(handles : array<riex_handle_t>#)
    for handle in handles
      using(handle) <| $(var desc : RendInstDesc#)
        if !desc.isValid
          return
        let collres = getRiGenCollisionResource(desc)
        if collres == null
          return
      out_list |> push(handle)

[es(tag=server, no_order)]
def voxel_grid_init_manager(info : UpdateStageInfoAct;
                            eid : EntityId;
                            transform : float3x4;
                            voxel_grid__step : float;
                            voxel_grid__resolution : int;
                            voxel_grid__minCollnodeRadius : float = 0.;
                            voxel_grid_init__trianglesPerUpdate : int;
                            voxel_grid_init__riExtras : UInt64List;
                            var voxel_grid_init__currentNode : int&;
                            var voxel_grid_init__currentTriangle : int&;
                            var voxel_grid_init__currentRi : int&;
                            var voxel_grid__voxels : BoolList&)
  var trianglesToProcess = voxel_grid_init__trianglesPerUpdate

  let riCount = length(voxel_grid_init__riExtras)
  if voxel_grid_init__currentRi >= riCount
    check_grid_connectivity(transform, voxel_grid__step, voxel_grid__resolution, voxel_grid__voxels)
    removeSubTemplate(eid, "voxel_grid_init_manager")
    return

  let invVoxelSize = safeinv(voxel_grid__step)
  let center = transform[3]
  let voxelBoxHalf = float(voxel_grid__resolution) * voxel_grid__step * 0.5
  let voxelBbox = BBox3(center - float3(voxelBoxHalf), center + float3(voxelBoxHalf))
  let voxelLocalBase = (center - float3(voxelBoxHalf)) * -invVoxelSize

  while voxel_grid_init__currentRi < riCount && trianglesToProcess > 0
    let handle = voxel_grid_init__riExtras[voxel_grid_init__currentRi]
    if rasterize_rendinst(handle, voxelBbox, voxelLocalBase, invVoxelSize, voxel_grid__minCollnodeRadius, voxel_grid__resolution,
                          voxel_grid_init__currentNode, voxel_grid_init__currentTriangle, trianglesToProcess, voxel_grid__voxels)
      voxel_grid_init__currentRi++
      voxel_grid_init__currentNode = 0

[es(on_appear, on_event=CmdVoxelGridRebuild)]
def voxel_grid_init_manager_add_subtemplate(evt : Event; eid : EntityId; voxel_grid_init__managerSubTemplate : string)
  if !empty(voxel_grid_init__managerSubTemplate)
    addSubTemplate(eid, voxel_grid_init__managerSubTemplate)

[es(tag=server, on_appear)]
def voxel_grid_init_manager_on_appear(evt : Event;
                                      transform : float3x4;
                                      voxel_grid__step : float;
                                      voxel_grid__resolution : int;
                                      var voxel_grid_init__riExtras : UInt64List&;
                                      var voxel_grid__voxels : BoolList&)
  let gridLen = voxel_grid__resolution * voxel_grid__resolution * voxel_grid__resolution
  voxel_grid__voxels |> resize(gridLen)
  for voxel in voxel_grid__voxels
    voxel = true

  let center = transform[3]
  let voxelBoxHalf = float3(float(voxel_grid__resolution) * voxel_grid__step * 0.5)
  let voxelBbox = BBox3(center - voxelBoxHalf, center + voxelBoxHalf)

  gather_ri_extras(voxelBbox, voxel_grid_init__riExtras)

[es(tag=server, on_appear, REQUIRE_NOT=voxel_grid_init__managerSubTemplate, on_event=CmdVoxelGridRebuild)]
def init_voxel_grid(evt : Event;
                    transform : float3x4;
                    voxel_grid__step : float;
                    voxel_grid__resolution : int;
                    voxel_grid__minCollnodeRadius : float = 0.;
                    var voxel_grid__voxels : BoolList&)
  init_voxels(transform, voxel_grid__step, voxel_grid__resolution, voxel_grid__minCollnodeRadius, voxel_grid__voxels)

[es(tag=server, on_appear, REQUIRE_NOT=voxel_grid_init__managerSubTemplate, on_event=CmdVoxelGridRebuild, after=init_voxel_grid, REQUIRE=voxel_grid__checkConnectivity)]
def init_voxel_grid_connectivity(evt : Event;
                                 transform : float3x4;
                                 voxel_grid__step : float;
                                 voxel_grid__resolution : int;
                                 var voxel_grid__voxels : BoolList&)
  check_grid_connectivity(transform, voxel_grid__step, voxel_grid__resolution, voxel_grid__voxels)
