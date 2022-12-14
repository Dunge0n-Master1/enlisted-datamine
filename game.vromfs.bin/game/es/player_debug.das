options no_aot
require ecs
require DagorConsole
require DagorDebug3D
require strings
require game.es.net_console_macro

[console_cmd(name="player.findByName")]
def console_player_find(playerName : string)
  createEntity("player_with_name_debug") <| $(var init : ComponentsInitializer)
    set(init, "name", playerName)

[net_console_cmd(name="player.rearm", hint="Restore soldier gun's ammo")]
def player_rearm_cmd(ammo : int = -1; [[net_hero]] hero : EntityId)
  query(hero) <| $ [es] (human_weap__weapInfo : Array)
    for weap in human_weap__weapInfo
      let weapObj = get_ecs_object(weap)
      if weapObj == null
        return
      let numReserveAmmo = (ammo == -1) ? (get_int(weapObj, "numReserveAmmo") ?? 0) : ammo
      let reserveAmmoTemplate = get_string(weapObj, "reserveAmmoTemplate", "")
      if reserveAmmoTemplate == ""
        continue
      for _i in range(numReserveAmmo)
        createEntity(reserveAmmoTemplate) <| $(var init)
          init |> set("item__lastOwner", hero)
          init |> set("item__ownerEid", hero)

[es(tag=render, no_order, REQUIRE=player_with_name_debug)]
def draw_founded_player(evt : UpdateStageInfoRenderDebug;
                        name aka found_name : string)
  query() <| $ [es(REQUIRE=player)] (name : string;
                                     possessed : EntityId)
    if found_name == name
      query(possessed) <| $ [es] (transform : float3x4)
        add_debug_text_mark(transform[3], name, -1, 0f, E3DCOLOR(0xFFFFFFFF))