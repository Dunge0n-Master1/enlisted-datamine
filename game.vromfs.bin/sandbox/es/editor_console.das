options no_aot
require ecs
require DngCamera
require DagorConsole
require game.es.teleport_common
require game.es.camera_common

[console_cmd(name="editor.test_mode")]
def editor_test_mode_cmd()
  let heroExist = find_query() <| $ [es(REQUIRE=hero)] (eid : EntityId)
    teleport_eid_to(eid, float3(0, 0, 0), /*use_camera_pos*/true)
    console_command("daEd4.open 0")
    return true

  if heroExist
    return

  // try find any respawner for team, if exist we not need to create a dev hero
  let respawnExist = find_query() <| $ [es(REQUIRE=respbase)] (team : int)
    return find_query() <| $ [es(REQUIRE=teamTag)] (team__id : int)
      return team == team__id

  if respawnExist
    console_command("daEd4.open 0")
    return

  var tm : float3x4
  tm |> identity()
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      tm = transform
      tm[3] = tm[3] + tm |> rotate <| float3(0f, 0f, 2f)
    return camera__active

  let finalizeCreation <- @ <| (heroEid : EntityId)
    find_query() <| $ [es(REQUIRE=player)] (eid : EntityId; is_local : bool)
      if is_local
        possess_entity_camera(heroEid, 0, eid, heroEid)
      return is_local
    console_command("daEd4.open 0")

  createEntity("editor_soldier+human_hero_components_local+observed_local", finalizeCreation) <| $(init)
    init |> set("transform", tm)
