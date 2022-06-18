require ecs
require DagorDriver3D
require RendInst
require WorldRenderer

def draw_collision_debug_common(phys : bool;
                                canopy : bool;
                                max_coll_dist_sq : float;
                                max_label_dist_sq : float)
  if get_grs_draw_wire()
    d3d_setwire(true)
  d3d_set_depth(worldRenderer_getDepthForDebug(), false)
  rendinst_drawDebugCollisions(int(DrawCollisionsFlags DRAW_COLLISIONS_ALL) |
                               int(DrawCollisionsFlags DRAW_COLLISIONS_OPACITY) |
                               int(DrawCollisionsFlags DRAW_COLLISIONS_WIREFRAME) |
                               (phys ? int(DrawCollisionsFlags DRAW_COLLISIONS_PHYS_ONLY) : 0) |
                               (canopy ? int(DrawCollisionsFlags DRAW_COLLISIONS_REND_INST_CANOPY) : 0),
                               true,
                               max_coll_dist_sq,
                               max_label_dist_sq)
  d3d_set_depth(null, false)
  if get_grs_draw_wire()
    d3d_setwire(false)

[es(tag=render, no_order, REQUIRE=collision_debug, on_event=RenderDebugWithJitter)]
def draw_collision_debug(evt : Event;
                         collision_debug__collMaxDistSq : float;
                         collision_debug__labelMaxDistSq : float)
  var canopy = false
  query() <| $ [es(REQUIRE=collision_canopy_debug)] ()
    canopy = true
  draw_collision_debug_common(false, canopy, collision_debug__collMaxDistSq, collision_debug__labelMaxDistSq)

[es(tag=render, no_order, REQUIRE=collision_phys_debug, on_event=RenderDebugWithJitter)]
def draw_phys_collision_debug(evt : Event;
                              collision_debug__collMaxDistSq : float;
                              collision_debug__labelMaxDistSq : float)
  var canopy = false
  query() <| $ [es(REQUIRE=collision_canopy_debug)] ()
    canopy = true
  draw_collision_debug_common(true, canopy, collision_debug__collMaxDistSq, collision_debug__labelMaxDistSq)
