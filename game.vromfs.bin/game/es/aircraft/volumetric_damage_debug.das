options no_aot
require ecs
require game.es.vehicle.vehicle_events
require DagorDebug3D
require DagorMath

[es(tag=dev, tag=render, REQUIRE=volumetric_damage_debug)]
def draw_volumetric_damages(evt : CmdVolumetricDamage; transform : float3x4)
  let wp = transform * evt.sph.c
  draw_debug_sphere_buffered(wp, evt.sph.r, E3DCOLOR(0xFF0000FF), 12, 200)
  draw_debug_sphere_buffered(wp, evt.damage / 25.0, E3DCOLOR(0xFFFF0000), 12, 200)
