options no_aot
require ecs
require math.color
require math.base
require DagorMath
require DagorDebug3D
require soundSystem
require soundHash


[es(tag=(sound, render), no_order)]
def volume_ambient_sound_debug(act : UpdateStageInfoRenderDebug;
                               eid : EntityId;
                               game_object_sound__name : string;
                               transform : float3x4;
                               game_object_sound__shape : uint;
                               volume_ambient_sound__extent_maxRadiusSq : float4)
  if get_enable_debug_draw()
    let color = E3DCOLOR(0xffffff00)
    add_debug_text_mark(transform[3], "{game_object_sound__name} {getEntityTemplateName(eid)}", -1, 0., color)
    if game_object_sound__shape == sound_hash("sphere")
      draw_debug_sphere_buffered(transform[3], volume_ambient_sound__extent_maxRadiusSq.x, color, 16, 1)
    elif game_object_sound__shape == sound_hash("capsule")
      assume pos = transform[3]
      let radius = volume_ambient_sound__extent_maxRadiusSq.x
      let halfHeight = volume_ambient_sound__extent_maxRadiusSq.y
      let up = transform[1] * halfHeight
      draw_debug_capsule_buffered(pos - up, pos + up, radius, color, 16, 1)
      draw_debug_tube_buffered(pos - up, pos + up, radius, color, 16, 0.1, 1)
    elif game_object_sound__shape == sound_hash("box")
      draw_debug_box_buffered(BBox3(-volume_ambient_sound__extent_maxRadiusSq.xyz, volume_ambient_sound__extent_maxRadiusSq.xyz), transform, color, 1)
    draw_debug_sphere_buffered(transform[3], sqrt(volume_ambient_sound__extent_maxRadiusSq.w), E3DCOLOR(0x80ffffff), 16, 1)
