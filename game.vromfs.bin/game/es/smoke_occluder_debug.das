options no_aot
require ecs
require DagorMath
require DagorDebug3D
require GamePhys
require DagorConsole


[console_cmd(name="smoke.debug")]
def smoke_occluder_debug_switch()
  let found = find_query() <| $ [es(REQUIRE=smokeOccluderDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !found
    createEntity("smoke_occluder_debug")

[es(tag=(render, dev), no_order, REQUIRE=smokeOccluderDebug)]
def draw_occluder_spheres_debug(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es] (transform : float3x4 const?;
                     smoke_occluder__sphere : float4)
    assume sphere = smoke_occluder__sphere
    draw_debug_sphere_buffered(sphere.xyz, sphere.w, E3DCOLOR(0xFF0000FF), 16, 10)

    if transform != null
      let pos = (*transform)[3]
      let posNormal = pos + (*transform)[1]
      let posWind = pos + get_wind()
      draw_cached_debug_line(pos, posNormal, E3DCOLOR(0xFFFF00FF))
      draw_cached_debug_line(pos, posWind, E3DCOLOR(0xFFFFFFFF))
