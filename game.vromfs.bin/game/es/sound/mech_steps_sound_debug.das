options no_aot
require ecs
require DagorMath
require math.color
require AnimV20
require GeomNodeTree
require DagorDebug3D
require soundSystem


def debug_draw_cross(wpos : float3; size : float; color : E3DCOLOR)
  let offset = float3(0., size, 0.)
  draw_debug_line_buffered(wpos - offset.yzz, wpos + offset.yzz, color, 1)
  draw_debug_line_buffered(wpos - offset.zyz, wpos + offset.zyz, color, 1)
  draw_debug_line_buffered(wpos - offset.zzy, wpos + offset.zzy, color, 1)


def debug_draw_node(node_name : string; animchar : AnimcharBaseComponent)
  let nodeIdx = geomtree_findNodeIndex(*animchar.nodeTree, node_name)
  if nodeIdx >= 0
    let wpos = *animchar.nodeTree |> geomtree_getNodeWpos(nodeIdx)
    add_debug_text_mark(wpos, "{node_name}", -1, 0., E3DCOLOR(0xFF0000FF))
    debug_draw_cross(wpos, 1.5, E3DCOLOR(0xFF00FF00))


[es(tag=(sound, render), no_order)]
def mech_steps_sound_draw_debug(act : UpdateStageInfoRenderDebug;
                                mech_steps_sound__feetNodes : StringList;
                                animchar : AnimcharBaseComponent)
  if get_enable_debug_draw()
    for nodeName in mech_steps_sound__feetNodes
      debug_draw_node(string(nodeName), animchar)
