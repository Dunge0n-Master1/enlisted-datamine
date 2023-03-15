options no_aot
require ecs
require ecs.ecs_template
require RendInst
require DagorDebug3D
require math.color
require DagorConsole

[ecs_template]
struct rendinst_debug_draw_bbox
  rendinst__debugDrawBBox : Tag

[console_cmd(name="rendinst.debug_draw_bbox")]
def rendinst_debug_draw_bbox_cmd()
  let found = find_query() <| $ [es(REQUIRE=rendinst__debugDrawBBox)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !found
    createEntity("rendinst_debug_draw_bbox")

[es(tag=(dev, render), no_order, REQUIRE=rendinst__debugDrawBBox)]
def rendinst_debug_draw_bbox_es(info : UpdateStageInfoAct)
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false

    gather_ri_gen_extra_collidable(BBox3(BSphere3(transform[3], 5.))) <| $(handles : array<riex_handle_t>#)
      for handle in handles
        using(handle) <| $(var desc : RendInstDesc#)
          using() <| $(var collInfo : CollisionInfo)
            desc |> getRiGenDestrInfo(collInfo)
            let box = collInfo.tm * collInfo.localBBox
            var seed = int(handle)
            draw_debug_box_buffered(box, rnd_color(seed), 1)
    return true
