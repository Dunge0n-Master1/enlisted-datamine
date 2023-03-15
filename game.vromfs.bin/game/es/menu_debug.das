options no_aot
require ecs
require ecs.ecs_template
require math.base
require CollRes
require DagorMath
require DagorDebug3D
require DagorConsole


[ecs_template]
struct draw_menu_item_debug
  draw_menu_item_debug : Tag

[console_cmd(name="menu_item.draw_rotation_center", hint="Draw rotation center for items displayed in menu")]
def draw_menu_item_debug_command()
  var found = false
  query() <| $ [es(REQUIRE=draw_menu_item_debug)] (eid : EntityId)
    destroyEntity(eid)
    found = true

  if !found
    createEntity("draw_menu_item_debug")
  console_print("{found ? "deactivate" : "activate"} menu item debug")

[es(no_order, REQUIRE=draw_menu_item_debug)]
def draw_menu_item_debug(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es] (transform : float3x4;
                     menu_item__boundingBoxCenter : float3;
                     menu_item__rotationOffset = float3(0.0))
    begin_draw_cached_debug_lines(false, false, false)
    set_cached_debug_lines_wtm(transform)

    let p = menu_item__boundingBoxCenter + menu_item__rotationOffset
    draw_cached_debug_sphere(p, 0.01f, E3DCOLOR(0xFFFFFFFF), 10)

    set_cached_debug_lines_wtm(IDENT_TM)
    end_draw_cached_debug_lines()
