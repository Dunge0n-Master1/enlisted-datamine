require ecs
require ecs.ecs_template
require DagorDebug3D
require game.es.net_console_macro


[ecs_template]
struct capzone_debug_draw
  capzoneDebug : Tag

[console_cmd(name="capzone.debug")]
def capzone_debug()
  query() <| $ [es(REQUIRE=capzone, REQUIRE_NOT=capzoneDebug)] (eid : EntityId)
    addSubTemplate(eid, "capzone_debug_draw")
  query() <| $ [es(REQUIRE=(capzone, capzoneDebug))] (eid : EntityId)
    removeSubTemplate(eid, "capzone_debug_draw")

[es(no_order, REQUIRE=capzoneDebug)]
def draw_box_capzones(info : UpdateStageInfoRenderDebug;
                      active : bool;
                      transform : float3x4)
  if active
    let box = transform * BBox3(-float3(0.5), float3(0.5))
    draw_debug_box_buffered(box, E3DCOLOR(0xFF00FF00), 1)
