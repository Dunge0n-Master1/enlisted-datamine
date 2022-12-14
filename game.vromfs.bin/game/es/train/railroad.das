require ecs
require gameObject
require game.utils.team
require game.es.battle_area_common
require enlisted.game.es.train.train_common
require %daslib.sort_boost


[es(on_appear, on_event=EventGameObjectsCreated)]
def init_railroad(evt : Event;
                  railroad__gameObjectType : string;
                  var railroad__points : Point3List)
  find_query() <| $ [es] (game_objects : GameObjects)
    let railroadScene = game_objects |> get_scene_game_objects_by_name(railroad__gameObjectType)
    if railroadScene != null
      let count = int(*railroadScene |> tiled_scene_getNodesCount())
      railroad__points |> resize(count)

      var pointInBattleArea = 0
      railroadScene |> find_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
        if !is_tm_outside_any_battle_area(tm, TEAM_UNASSIGNED)
          railroad__points[pointInBattleArea++] = tm[3]
        return false

      railroad__points |> resize(pointInBattleArea)

      qsort(railroad__points) <| $(a, b) { return compare_points(a, b); }

    return true
