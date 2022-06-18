options no_aot
require ecs
require DagorMath
require DagorConsole
require DagorDebug3D

[console_cmd(name="render.show_deformable_bboxes")]
def deformables_debug()
  var found = false
  query() <| $ [es(REQUIRE=deformablesDebug)] (eid : EntityId)
    destroyEntity(eid)
    found = true

  if !found
    createEntity("deformables_debug")

[es(tag=dev, tag=render, no_order, REQUIRE=deformablesDebug)]
def deformables_debug_draw_es(evt : UpdateStageInfoRenderDebug)
  begin_draw_cached_debug_lines(true, true, false)

  query() <| $ [es] (transform : float3x4; deform_bbox__bmin : float3&; deform_bbox__bmax : float3&)
    let itm = inverse(transform)
    let box = BBox3(deform_bbox__bmin - float3(0.25, 0.25, 0.25), deform_bbox__bmax + float3(0.25, 0.25, 0.25))
    var inflated_box = box
    inflated_box |> bbox3_add(box.center + itm[1])
    inflated_box = transform * inflated_box
    draw_cached_debug_box(inflated_box, E3DCOLOR(0xFFFFFFFF))

  end_draw_cached_debug_lines()

