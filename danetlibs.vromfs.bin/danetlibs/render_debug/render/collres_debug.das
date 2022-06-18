options no_aot
require ecs
require DagorConsole
require AnimV20
require CollRes
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

[es(REQUIRE=drawCollisionResource, no_order)]
def debug_dynamic_collision(info : UpdateStageInfoRenderDebug)
  query() <| $ [es] (transform : float3x4; camera__active : bool)
    if !camera__active
      return
    let camPos = transform[3]
    let camDist = 100.0
    begin_draw_cached_debug_lines(true, true, false)
    query() <| $ [es] (transform : float3x4; collres : CollisionResource; animchar : AnimcharBaseComponent)
      if length_sq(transform[3] - camPos) >= square(camDist)
        return
      let numNodes = collres_get_nodesCount(collres)
      let color = E3DCOLOR(0xFF00FF00)
      for i in range(numNodes)
        let node = collres_get_node(collres, i)
        var nodeTm : float3x4
        collres_get_collision_node_tm(collres, i, transform, animchar.nodeTree, nodeTm)
        set_cached_debug_lines_wtm(nodeTm)
        get_collnode_geom(node) <| $(indices; vertices)
          for idx in range(length(indices) / 3)
            let v0 = float3_xyz(vertices[int(indices[idx * 3 + 0])])
            let v1 = float3_xyz(vertices[int(indices[idx * 3 + 1])])
            let v2 = float3_xyz(vertices[int(indices[idx * 3 + 2])])
            draw_cached_debug_line(v0, v1, color)
            draw_cached_debug_line(v1, v2, color)
            draw_cached_debug_line(v2, v0, color)
    end_draw_cached_debug_lines()
