options no_aot
require ecs
require DagorMath
require DagorDebug3D
require soundSystem
require math.color


def get_color(idx : int)
  let colors = [[E3DCOLOR[6] E3DCOLOR(0xffffffff); E3DCOLOR(0xffffff40); E3DCOLOR(0xffff4040); E3DCOLOR(0xff8040ff); E3DCOLOR(0xff404040); E3DCOLOR(0xff40ff40)]]
  return colors[idx % 6]


def is_border(seg : float4)
  return (int(seg.x) & 1) != 0


[es(no_order, tag=(render, sound))]
def ocean_sound_debug_draw(info : UpdateStageInfoRenderDebug;
                           ocean_sound__points : Point4List;
                           ocean_sound__waterLevel : float)
  if !get_enable_debug_draw()
    return
  var idx = -1
  var splineIdx = 0
  for p in ocean_sound__points
    ++idx
    if length_sq(p) != 0.
      let pos = float3(p.x, ocean_sound__waterLevel, p.y)
      add_debug_text_mark(pos, "{idx}", -1, 0., get_color(splineIdx))
      draw_debug_line_buffered(float3(p.x, ocean_sound__waterLevel + 1., p.y), float3(p.z, ocean_sound__waterLevel + 1., p.w), is_border(p) ? E3DCOLOR(0xff000000) : get_color(splineIdx), 2)
    else
      ++splineIdx
