options no_aot
require ecs
require EnlistedPhysObj
require ecs.ecs_template
require DagorConsole
require DagorDebug3D


[ecs_template]
struct physobj_ccd_debug_draw
  physobj_ccd_debug_draw : Tag


[es(tag=dev, no_order, REQUIRE=physobj_ccd_debug_draw)]
def physobj_ccd_debug_es(info : UpdateStageInfoRenderDebug)
  begin_draw_cached_debug_lines(true, true, false)
  query() <| $ [es] (phys_obj_net_phys : PhysObjActor; transform : float3x4)
    for sphere in phys_obj_net_phys.phys.ccdSpheres
      let pos = transform * sphere.c
      draw_cached_debug_sphere(pos, sphere.r, E3DCOLOR(0xFF00FF00), 12)
  end_draw_cached_debug_lines()


[console_cmd(name="physobj.draw_ccd", hint="Draw physobj ccd spheres")]
def physob_ccd_debug_cmd()
  let found = find_query() <| $ [es(REQUIRE=physobj_ccd_debug_draw)] (eid : EntityId)
    destroyEntity(eid)
    return true

  if !found
    createEntity("physobj_ccd_debug_draw")
