options no_aot
require ecs
require ecs.ecs_template
require DagorConsole
require AnimV20
require CollRes
require GeomNodeTree
require EnlistedCamera
require RendInst
require Dacoll
require PhysMat
require RendInst
require DagorDebug3D
require DagorSystem
require math.base
require strings

[console_cmd(name="collision.draw_coll_res")]
def toggle_draw_coll_res(activate : bool = true)
  var exists = false
  query() <| $ [es(REQUIRE=drawCollisionResource)] (eid : EntityId)
    destroyEntity(eid)
    exists = true
  if !exists
    createEntity("debug_dyn_collision")

def draw_nodes(collres : CollisionResource; transform : float3x4; animchar : AnimcharBaseComponent const?; color : E3DCOLOR)
  let numNodes = collres_get_nodesCount(collres)
  for i in range(numNodes)
    let node = collres_get_node(collres, i)
    var nodeTm : float3x4
    collres_get_collision_node_tm(collres, i, transform, animchar != null ? animchar.nodeTree : null, nodeTm)
    set_cached_debug_lines_wtm(nodeTm)
    if node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_MESH))
      get_collnode_geom(node) <| $(indices; vertices)
        for idx in range(length(indices) / 3)
          let v0 = vertices[int(indices[idx * 3 + 0])].xyz
          let v1 = vertices[int(indices[idx * 3 + 1])].xyz
          let v2 = vertices[int(indices[idx * 3 + 2])].xyz
          draw_cached_debug_line(v0, v1, color)
          draw_cached_debug_line(v1, v2, color)
          draw_cached_debug_line(v2, v0, color)

    if node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_BOX))
      draw_cached_debug_box(node.modelBBox, color)
    if node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_SPHERE))
      draw_cached_debug_sphere(node.boundingSphere.c, node.boundingSphere.r, color, 12)
    if node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_CAPSULE))
      draw_cached_debug_capsule_w(node.capsule, color)

[es(REQUIRE=drawCollisionResource, no_order)]
def debug_dynamic_collision(info : UpdateStageInfoRenderDebug)
  query() <| $ [es] (transform : float3x4; camera__active : bool)
    if !camera__active
      return
    let camPos = transform[3]
    let camDist = 16.0
    begin_draw_cached_debug_lines(true, true, false)
    query() <| $ [es] (transform : float3x4; collres : CollisionResource; animchar : AnimcharBaseComponent const?)
      if length_sq(transform[3] - camPos) >= square(camDist)
        return
      let color = E3DCOLOR(0xFF00FF00)
      draw_nodes(collres, transform, animchar, color)

    rendinst_foreachRIGenInBox(BBox3(BSphere3(camPos, camDist)), true) <| $(desc : RendInstDesc; tm : float3x4; is_tm : bool)
      if length_sq(tm[3] - camPos) >= square(camDist)
        return
      let collres = getRiGenCollisionResource(desc)
      if collres == null
        return
      let color = E3DCOLOR(is_tm ? 0xFF00FF00 : 0xFFFF0000)
      draw_nodes(*collres, tm, null, color)
      let pos = tm[3]
      add_debug_text_mark(pos, "{getRIGenResName(desc)}", -1, 0., color)

    end_draw_cached_debug_lines()

[ecs_template]
struct collision_ruler_debug
  collisionRulerDebug : bool

def get_node_type_name(node_type : uint8)
  if node_type == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_MESH))
    return "mesh"
  if node_type == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_POINTS))
    return "points"
  if node_type == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_BOX))
    return "box"
  if node_type == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_SPHERE))
    return "sphere"
  if node_type == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_CAPSULE))
    return "capsule"
  if node_type == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_CONVEX))
    return "convex"
  return "unknown"

[console_cmd(name="collision.ruler")]
def draw_ruler()
  let found = find_query() <| $ [es(REQUIRE=collisionRulerDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !found
    createEntity("collision_ruler_debug")

def format_scale(flags : uint8; tm : float3x4)
  if (uint(flags) & uint(CollisionNodeFlag IDENT)) != 0u
    return "identity"
  if (uint(flags) & uint(CollisionNodeFlag TRANSLATE)) != 0u
    return "translate"
  if (uint(flags) & uint(CollisionNodeFlag ORTHONORMALIZED)) != 0u
    return "orthonormalized"
  if (uint(flags) & uint(CollisionNodeFlag ORTHOUNIFORM)) != 0u
    return "orthouniform" + format(" (scale %.1f)", length(tm[0])) + " [{abs(length_sq(tm[0]) - 1.0)}]"
  return format("scaled: %f | ", length(tm[0])) + format("%f | ", length(tm[1])) + format("%f", length(tm[2]))

def format_scale(tm : float3x4)
  var flags = uint8(0)
  let len0sq = length_sq(tm[0])
  let len1sq = length_sq(tm[1])
  let len2sq = length_sq(tm[2])
  if abs(dot(tm[0], tm[1])) < 1e-3f && abs(dot(tm[0], tm[2])) < 1e-3f && abs(dot(tm[1], tm[2])) < 1e-3f
    if abs(len1sq - len0sq) < len0sq * 1e-3f && abs(len2sq - len0sq) < len0sq * 1e-3f
      flags = abs(len0sq - 1.f) < 1e-3f ? uint8(CollisionNodeFlag ORTHONORMALIZED) : uint8(CollisionNodeFlag ORTHOUNIFORM)
  return format_scale(flags, tm)

def draw_collres_node_debug(name : string; cam_itm, transform : float3x4; animchar : AnimcharBaseComponent const?; dist : float; best_node_idx : int; intersection_pos : float3; collres : CollisionResource)
  let markOffsetScale = dist * 0.22
  let markPos = intersection_pos + cam_itm[0] * markOffsetScale + cam_itm[1] * markOffsetScale * 0.5
  let node = collres |> collres_get_node(best_node_idx)
  let nodeTree = animchar != null ? animchar.nodeTree : null
  var ntm : float3x4
  collres |> collres_get_collision_node_tm(int(node.nodeIndex), transform, nodeTree, ntm)
  draw_debug_sphere_buffered(transform * collres.boundingSphere.c, collres.boundingSphere.r, E3DCOLOR(0xFFBBBB00), 24, 1)
  draw_debug_box_buffered(node.modelBBox, ntm, E3DCOLOR(0xFFBF00FF), 1)
  var nodeType = "; type: {get_node_type_name(node.nodeType)}"
  if node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_MESH)) || node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_CONVEX))
    get_collnode_geom(node) <| $ [unused_argument(vertices)] (indices; vertices)
      nodeType += " ({length(indices) / 3} triangles)"
  nodeType += "; " + format_scale(node.flags, node.tm)
  var meshCnt, triCnt, ptCnt, boxCnt, sphCnt, capCnt, cvxCnt : int
  let nodesCnt = collres |> collres_get_nodesCount()
  var scaledCnt = 0
  var notUniformCnt = 0
  for i in range(nodesCnt)
    let inode = collres |> collres_get_node(i)
    if inode.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_MESH))
      meshCnt++
      if (uint(inode.flags) & uint(CollisionNodeFlag ORTHONORMALIZED)) == 0u
        scaledCnt++
      if (uint(inode.flags) & (uint(CollisionNodeFlag ORTHONORMALIZED) | uint(CollisionNodeFlag ORTHOUNIFORM))) == 0u
        notUniformCnt++
      get_collnode_geom(inode) <| $ [unused_argument(vertices)] (indices; vertices)
        triCnt += length(indices) / 3
    if inode.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_POINTS))
      ptCnt++
    if inode.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_BOX))
      boxCnt++
    if inode.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_SPHERE))
      sphCnt++
    if inode.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_CAPSULE))
      capCnt++
    if inode.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_CONVEX))
      cvxCnt++
  var nodesText = "Total nodes: {nodesCnt}"
  if meshCnt != 0
    nodesText += "; mesh: {meshCnt} (triangles: {triCnt}"
  if scaledCnt != 0
    nodesText += "; scaled: {scaledCnt}"
  if notUniformCnt != 0
    nodesText += "; not uniform: {notUniformCnt}"
  if meshCnt != 0
    nodesText += ")"
  if ptCnt != 0
    nodesText += "; pt: {ptCnt}"
  if boxCnt != 0
    nodesText += "; box: {boxCnt}"
  if sphCnt != 0
    nodesText += "; sph: {sphCnt}"
  if capCnt != 0
    nodesText += "; cap: {capCnt}"
  if cvxCnt != 0
    nodesText += "; cvx: {cvxCnt}"
  add_debug_text_mark(markPos, name, -1, 0.0, E3DCOLOR(0xFF8FFF8F))
  add_debug_text_mark(markPos, format("dist %.2fm; tm ", dist) + format_scale(transform), -1, 1.2, E3DCOLOR(0xFF8FFF8F))
  add_debug_text_mark(markPos, "node {best_node_idx}: {node |> collnode_get_name()}" + nodeType, -1, 2.4, E3DCOLOR(0xFF8FFF8F))
  add_debug_text_mark(markPos, nodesText, -1, 3.6, E3DCOLOR(0xFF8FFF8F))
  add_debug_text_mark(markPos, "Grids: trace={collres |> collres_check_grid_available(uint8(BehaviorFlag TRACEABLE))} coll={collres |> collres_check_grid_available(uint8(BehaviorFlag PHYS_COLLIDABLE))}", -1, 4.8, E3DCOLOR(0xFF8FFF8F))

[es(tag=render, no_order, REQUIRE=collisionRulerDebug)]
def draw_collision_ruler_es(evt : UpdateStageInfoRenderDebug)
  let camItm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camItm == null
    return
  let cameraPos = (*camItm)[3] - float3(0.0, 0.05, -0.075)
  let cameraDir = (*camItm)[2]

  var bestT = 4000.0
  var bestEid = INVALID_ENTITY_ID
  var bestNodeIdx = -1
  ecs::query() <| $ [es] (eid : EntityId; transform : float3x4; collres : CollisionResource; animchar : AnimcharBaseComponent const?; grid_obj__centerNodeIdx : int = -1)
    let nodeTree = animchar != null ? animchar.nodeTree : null
    collres |> collres_traceray(transform, nodeTree, cameraPos, cameraDir, bestT, true, float4(0.0, 0.0, 0.0, 1.0), grid_obj__centerNodeIdx, uint8(BehaviorFlag TRACEABLE)) <| $(is_hit : bool; isects : CollResIntersectionsType#)
      if is_hit
        bestT = isects[0].intersectionT
        bestEid = eid
        bestNodeIdx = int(isects[0].collisionNodeId)

  var riDesc = RendInstDesc()
  var norm : float3
  var matId = PHYSMAT_INVALID
  let res = traceray_normalized(cameraPos, cameraDir, bestT, matId, norm, ETF_RI, riDesc, -1)
  let intersectionPos = cameraPos + cameraDir * bestT
  if res && riDesc.isValid
    let collres = getRiGenCollisionResource(riDesc)
    if collres != null
      let riTm = getRIGenMatrix(riDesc)
      bestT += 0.01
      *collres |> collres_traceray(riTm, null, cameraPos, cameraDir, bestT, true, float4(0.0, 0.0, 0.0, 1.0), -1, uint8(BehaviorFlag TRACEABLE)) <| $(is_hit : bool; isects : CollResIntersectionsType#)
        if is_hit
          bestT = isects[0].intersectionT
          bestEid = INVALID_ENTITY_ID
          bestNodeIdx = int(isects[0].collisionNodeId)
          draw_collres_node_debug(getRIGenResName(riDesc), *camItm, riTm, null, bestT, bestNodeIdx, intersectionPos, *collres)

  ecs::query(bestEid) <| $ [es] (transform : float3x4; collres : CollisionResource; animchar : AnimcharBaseComponent const?)
    draw_collres_node_debug("{getEntityTemplateName(bestEid)}", *camItm, transform, animchar, bestT, bestNodeIdx, intersectionPos, collres)

  draw_debug_line_buffered(cameraPos, intersectionPos, E3DCOLOR(0xFFFF2020), 5)
  //draw_debug_sphere_buffered(intersectionPos, 0.12, E3DCOLOR(0xFFFF2020), 24, 1)
