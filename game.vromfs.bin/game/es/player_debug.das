options no_aot
require ecs
require DagorConsole
require DagorDebug3D
require strings

[console_cmd(name="player.findByName")]
def console_player_find(playerName : string)
  createEntity("player_with_name_debug") <| $(var init : ComponentsInitializer)
    set(init, "name", playerName)


[es(tag=render, no_order, REQUIRE=player_with_name_debug)]
def draw_founded_player(evt : UpdateStageInfoRenderDebug;
                        name aka found_name : string)
  query() <| $ [es(REQUIRE=player)] (name : string;
                                     possessed : EntityId)
    if found_name == name
      query(possessed) <| $ [es] (transform : float3x4)
        add_debug_text_mark(transform[3], name, -1, 0f, E3DCOLOR(0xFFFFFFFF))