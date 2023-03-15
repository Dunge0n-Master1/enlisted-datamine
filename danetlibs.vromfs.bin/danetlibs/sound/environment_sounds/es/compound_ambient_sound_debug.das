options no_aot
require ecs
require math.color
require math.base
require DagorMath
require DagorDebug3D
require soundSystem
require soundHash


[es(tag=(sound, render), no_order)]
def compound_ambient_sound_debug(act : UpdateStageInfoRenderDebug;
                                 eid : EntityId;
                                 game_object_sound__name : string;
                                 game_object_compound_sound__shapes : UInt32List;
                                 game_object_compound_sound__transforms : TMatrixList;
                                 //compound_ambient_sound__closestDistSq : float;
                                 //global_sound_listener_position : float3;
                                 //compound_ambient_sound__closestPt : float3;
                                 compound_ambient_sound__extents_maxRadiusSq : Point4List)
  if get_enable_debug_draw()
    //let pt = compound_ambient_sound__closestDistSq > 0. ? compound_ambient_sound__closestPt : global_sound_listener_position
    //draw_debug_sphere_buffered(pt, 0.1, E3DCOLOR(0xffffffff), 8, 1)

    for tm, shape, extent in game_object_compound_sound__transforms, game_object_compound_sound__shapes, compound_ambient_sound__extents_maxRadiusSq
      let color = E3DCOLOR(0xffffff00)
      add_debug_text_mark(tm[3], "{game_object_sound__name} {getEntityTemplateName(eid)}", -1, 0., color)
      if shape == sound_hash("sphere")
        draw_debug_sphere_buffered(tm[3], extent.x, color, 16, 1)
      elif shape == sound_hash("capsule")
        assume pos = tm[3]
        let radius = extent.x
        let halfHeight = extent.y
        let up = tm[1] * halfHeight
        draw_debug_capsule_buffered(pos - up, pos + up, radius, color, 16, 1)
        draw_debug_tube_buffered(pos - up, pos + up, radius, color, 16, 0.1, 1)
      elif shape == sound_hash("box")
        draw_debug_box_buffered(BBox3(-extent.xyz, extent.xyz), tm, color, 1)
      draw_debug_sphere_buffered(tm[3], sqrt(extent.w), E3DCOLOR(0x80ffffff), 16, 1)
