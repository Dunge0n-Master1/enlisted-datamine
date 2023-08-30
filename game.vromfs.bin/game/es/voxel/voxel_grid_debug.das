options no_aot
require ecs
require DagorDebug3D
require DagorConsole
require game.events_game
require game.es.voxel.voxel_grid_common
require ecs.ecs_template

[ecs_template(tag=dev)]
struct voxel_debug
  voxel_grid__debug : Tag

[console_cmd(name="voxel.rebuild")]
def console_rebuild_voxel()
  query() <| $ [es(REQUIRE=voxel_grid__voxels)] (eid : EntityId)
    sendEvent(eid, [[CmdVoxelGridRebuild]])

[console_cmd(name="voxel.debug")]
def console_toggle_voxel_draw()
  var found = false
  query() <| $ [es(REQUIRE=voxel_grid__debug)] (eid : EntityId)
    found = true
    removeSubTemplate(eid, "voxel_debug")
  if !found
    query() <| $ [es(REQUIRE=voxel_grid__voxels)] (eid : EntityId)
      addSubTemplate(eid, "voxel_debug")

def draw_voxel(tm : float3x4; index : int; dimension : int; side : float; color)
  let box = get_voxel_box(tm, index, dimension, side)
  draw_debug_box_buffered(box, color, 1)

[es(no_order, REQUIRE=voxel_grid__debug)]
def voxel_grid_draw(info : UpdateStageInfoRenderDebug;
                    transform : float3x4;
                    voxel_grid__resolution : int;
                    voxel_grid__step : float;
                    voxel_grid__voxels : BoolList)
  for voxel, index in voxel_grid__voxels, count()
    if voxel
      draw_voxel(transform, index, voxel_grid__resolution, voxel_grid__step, E3DCOLOR(0xFFFF0000))
