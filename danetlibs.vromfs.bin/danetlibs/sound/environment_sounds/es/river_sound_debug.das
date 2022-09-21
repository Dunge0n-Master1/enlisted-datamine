options no_aot
require ecs
require DagorMath
require DagorDebug3D
require soundSystem
require Dacoll

let DEBUG_ADD_DRAW_HEIGHT = 1.

[es(no_order, tag=(render, sound))]
def river_sound_debug_draw(info : UpdateStageInfoRenderDebug;
                           river_sound__points : Point3List)
  if !get_enable_debug_draw()
    return
  var idx = 0
  for pt in river_sound__points
    if pt.z != 0.
      var pos = float3(pt.x, 0., pt.y)
      traceht_water(pos, pos.y)
      pos.y += DEBUG_ADD_DRAW_HEIGHT
      draw_debug_sphere_buffered(pos, pt.z, E3DCOLOR(0xffffffff), 24, 1)
      draw_debug_line_buffered(pos, pos + float3(20., 0., 0.), E3DCOLOR(0xffff0000), 2)
      draw_debug_line_buffered(pos, pos + float3(0., 0., 20.), E3DCOLOR(0xff0000ff), 2)
      add_debug_text_mark(pos, "{idx}", -1, 0., E3DCOLOR(0xffffffff))
    ++idx

  idx = 0
  while idx + 1 < length(river_sound__points)
    let p0 = river_sound__points[idx]
    let p1 = river_sound__points[idx + 1]
    if p1.z == 0.
      idx += 2
    else
      var a = float3(p0.x, 0., p0.y)
      var b = float3(p1.x, 0., p1.y)
      traceht_water(a, a.y)
      traceht_water(b, b.y)
      a.y += DEBUG_ADD_DRAW_HEIGHT
      b.y += DEBUG_ADD_DRAW_HEIGHT
      let tan = normalize(float3(b.z - a.z, 0., a.x - b.x))
      draw_debug_line_buffered(a + tan * p0.z, b + tan * p1.z, E3DCOLOR(0xffffffff), 2)
      draw_debug_line_buffered(a - tan * p0.z, b - tan * p1.z, E3DCOLOR(0xffffffff), 2)
      ++idx
