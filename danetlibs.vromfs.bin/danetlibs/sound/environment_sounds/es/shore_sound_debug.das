options no_aot
require ecs
require math.base
require DagorMath
require DagorDebug3D
require soundSystem


[es(no_order, tag=(render, sound, dev))]
def shore_sound_debug_draw(info : UpdateStageInfoRenderDebug;
                           shore_sound__offsets : Point2List;
                           transform : float3x4)
  if !get_enable_debug_draw()
    return
  for idx in range(length(shore_sound__offsets) - 1)
    draw_debug_line_buffered(transform * float3(shore_sound__offsets[idx].x, 0., shore_sound__offsets[idx].y),
                             transform * float3(shore_sound__offsets[idx + 1].x, 0., shore_sound__offsets[idx + 1].y),
                             E3DCOLOR(0xffffffff), 2)
  if length(shore_sound__offsets) >= 2
    draw_debug_line_buffered(transform * float3(shore_sound__offsets[0].x, 0., shore_sound__offsets[0].y),
                             transform * float3(shore_sound__offsets[length(shore_sound__offsets) - 1].x, 0., shore_sound__offsets[length(shore_sound__offsets) - 1].y),
                             E3DCOLOR(0xff8000ff), 2)
