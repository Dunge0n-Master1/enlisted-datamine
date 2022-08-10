options no_aot
require ecs
require DagorConsole
require AnimV20
require CollRes
require RendInst
require Dacoll
require DagorDebug3D
require DagorSystem
require math.base

[console_cmd(name="collision.draw_coll_res")]
def toggle_draw_coll_res(activate : bool = true)
  var exists = false
  query() <| $ [es(REQUIRE=drawCollisionResource)] (eid : EntityId)
    destroyEntity(eid)
    exists = true
  if !exists
    createEntity("debug_dyn_collision")

def float3_xyz(a)
  return float3(a.x, a.y, a.z)

def draw_nodes(collres : CollisionResource; transform : float3x4; animchar : AnimcharBaseComponent?; color : E3DCOLOR)
  let numNodes = collres_get_nodesCount(collres)
  for i in range(numNodes)
    let node = collres_get_node(collres, i)
    var nodeTm : float3x4
    collres_get_collision_node_tm(collres, i, transform, animchar != null ? animchar.nodeTree : null, nodeTm)
    set_cached_debug_lines_wtm(nodeTm)
    if node.nodeType == uint8(int(CollisionResourceNodeType COLLISION_NODE_TYPE_MESH))
      get_collnode_geom(node) <| $(indices; vertices)
        for idx in range(length(indices) / 3)
          let v0 = float3_xyz(vertices[int(indices[idx * 3 + 0])])
          let v1 = float3_xyz(vertices[int(indices[idx * 3 + 1])])
          let v2 = float3_xyz(vertices[int(indices[idx * 3 + 2])])
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
    query() <| $ [es] (transform : float3x4; collres : CollisionResource; animchar : AnimcharBaseComponent?)
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
