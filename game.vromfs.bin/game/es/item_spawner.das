require ecs
require game.utils.team

[es(tag=server, on_event=EventLevelLoaded)]
def item_spawner(evt : Event;
                 transform : float3x4;
                 spawnItemList : Array;
                 spawnItemStep : float3;
                 team : int = TEAM_UNASSIGNED)
  var tm = transform
  for itemC in spawnItemList
    let item = get_ecs_object(itemC)
    let count = item |> get_int("count") ?? 1
    let templ = item |> get_string("templ", "")

    if templ == ""
      return

    for _i in 0..count
      createEntity(templ) <| $(init)
        init |> set("team", team)
        init |> set("transform", tm)
      tm[3] += spawnItemStep