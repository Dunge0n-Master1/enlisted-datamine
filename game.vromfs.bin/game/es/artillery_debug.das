options no_aot
require ecs
require ecs.ecs_template
require DagorConsole
require DagorDebug3D

[ecs_template]
struct artillery_debug_draw
  artilleryDebug : Tag

[es(tag=dev, on_appear)]
def artillery_point_debug_es(evt : Event; auto_shoot__gunPos : float3; auto_shoot__targetPos : float3)
  query() <| $ [es(REQUIRE=artilleryDebug)]
    draw_debug_sphere_buffered(auto_shoot__targetPos, 1f, E3DCOLOR(0xFF00FF00), 12, 30000)
    draw_debug_sphere_buffered(auto_shoot__gunPos, 1f, E3DCOLOR(0xFFFF0000), 12, 30000)

[console_cmd(name="artillery.debug")]
def artillery_debug_cmd()
  let found = find_query() <| $ [es(REQUIRE=artilleryDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true

  if !found
    createEntity("artillery_debug_draw")