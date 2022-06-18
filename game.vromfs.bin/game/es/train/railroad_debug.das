options no_aot
require ecs
require ecs.ecs_template
require Dacoll
require DagorMath
require DagorDebug3D
require DagorConsole
require enlisted.game.es.train.train_common


[ecs_template]
struct railroad_debug_draw
  railroadDebug : Tag


[console_cmd(name="railroad.debug")]
def railroad_debug()
  query() <| $ [es(REQUIRE=railroad, REQUIRE_NOT=railroadDebug)] (eid : EntityId)
    addSubTemplate(eid, "railroad_debug_draw")
  query() <| $ [es(REQUIRE=(railroad, railroadDebug))] (eid : EntityId)
    removeSubTemplate(eid, "railroad_debug_draw")


[es(no_order, REQUIRE=railroadDebug)]
def draw_railroad(info : UpdateStageInfoRenderDebug; railroad__points : Point3List)
  for i in range(1, length(railroad__points))
    let cur  = railroad__points[i]
    let prev = railroad__points[i - 1]
    draw_debug_line_buffered(prev, cur, E3DCOLOR(0xFF00FF00), 1)

    draw_debug_sphere_buffered(cur, 0.5, E3DCOLOR(0xFF0000FF), 4, 1)

    query() <| $ [es] (camera__active : bool; transform : float3x4)
      if camera__active
        let traceDir = transform[2]
        let tracePos = transform[3]
        var len = 500f
        var norm : float3
        if traceray_normalized(tracePos, traceDir, len, norm)
          let p = tracePos + traceDir * len
          draw_debug_sphere_buffered(p, 0.5, E3DCOLOR(0xFF00FF00), 4, 1)

          let projected = project_on_railroad(p)
          draw_debug_sphere_buffered(projected, 1.5, E3DCOLOR(0xFFFF00FF), 4, 1)

          draw_debug_line_buffered(p, projected, E3DCOLOR(0xFFFF00FF), 1)
