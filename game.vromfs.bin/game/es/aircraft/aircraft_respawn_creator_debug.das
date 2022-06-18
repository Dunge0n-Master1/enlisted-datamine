options no_aot
require ecs
require DagorMath
require DagorConsole
require DagorDebug3D
require ecs.ecs_template

[ecs_template]
struct aircraft_respawn_creator_debug
  aircraft_respawn_creator__debug : Tag

[console_cmd(name="aircraft_respawn_creator.debug")]
def aircraft_respawn_creator_debug()
  let exist = find_query() <| $ [es(REQUIRE=aircraft_respawn_creator__debug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !exist
    createEntity("aircraft_respawn_creator_debug")

[es(tag=(dev, gameClient), REQUIRE=aircraft_respawn_creator__debug, no_order)]
def aircraft_respawn_creator_debug_es(info : UpdateStageInfoRenderDebug)
  query() <| $ [es(REQUIRE=planeResupply)] (transform : float3x4; resupply_zone__team : int)
    draw_debug_sphere_buffered(transform[3], 20.0f, resupply_zone__team == 1 ? E3DCOLOR(0xFFFF0000) : E3DCOLOR(0xFF00FF00), 24, 100)
  query() <| $ [es(REQUIRE=aircraftRespbase)] (transform : float3x4; team : int)
    draw_debug_sphere_buffered(transform[3], 20.0f, team == 1 ? E3DCOLOR(0xFFE99904) : E3DCOLOR(0xFF06D9F5), 24, 100)
  query() <| $ [es] (respawn_creator__middlePos : float3;
                     respawn_creator__dirMult : float;
                     respawn_creator__additionalHeight : float)
    var pos = respawn_creator__middlePos
    pos[1] += respawn_creator__additionalHeight
    draw_debug_sphere_buffered(pos, respawn_creator__dirMult, E3DCOLOR(0xFFEA07F1), 24, 100)
