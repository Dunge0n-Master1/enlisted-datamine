options no_aot
require ecs
require ecs.ecs_template
require DagorDebug3D
require DagorMath
require AnimV20
require GeomNodeTree
require game.es.net_console_macro


[ecs_template]
struct gun_attachable_check_points_debug
  gun_attachable_check_points_debug : Tag

[net_console_cmd(name="gun_attachable.draw_check_points", hint="Draw gun attachable check points. Blue for down, Red for FromTo points.")]
def gun_attachable_check_points_cmd()
  let exist = find_query() <| $ [es(REQUIRE=gun_attachable_check_points_debug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !exist
    createEntity("gun_attachable_check_points_debug")
  console_print("gun attachable check points debug {exist ? "disabled" : "enabled"}")

[es(tag=(dev, render), no_order, REQUIRE=gun_attachable_check_points_debug)]
def draw_gun_attachable_check_points(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es] (transform : float3x4;
                     animchar : AnimcharBaseComponent;
                     gun_autodetach__nodeId : int;
                     gun_attachable_check__pointsFromTo : Array;
                     gun_attachable_check__pointsDown : Point3List)
    begin_draw_cached_debug_lines(true, true, false)

    var gunTm = transform
    if gun_autodetach__nodeId >= 0
      geomtree_getNodeWtmScalar(*animchar.nodeTree, gun_autodetach__nodeId, gunTm)

    for pt in gun_attachable_check__pointsDown
      let from = gunTm * pt
      let to = from + float3(0.0, -10.0, 0.0)
      draw_cached_debug_line(from, to, E3DCOLOR(0xFF0000FF))

    for pt in gun_attachable_check__pointsFromTo
      let obj = get_ecs_object(pt)
      if obj == null
        continue
      let from = gunTm * (*obj |> get_Point3("from") ?? float3())
      let to = gunTm * (*obj |> get_Point3("to") ?? float3())
      draw_cached_debug_line(from, to, E3DCOLOR(0xFFFF0000))

    end_draw_cached_debug_lines()
