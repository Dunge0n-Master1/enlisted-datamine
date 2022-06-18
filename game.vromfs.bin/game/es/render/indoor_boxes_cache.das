require ecs
require gameObject


[es(on_event=EventGameObjectsCreated, tag=(dev, render), before=(move_indoor_light_probes_to_render_es, gi_objects_es))]
def on_game_objects_created(evt : Event; var indoorBoxes__transforms : TMatrixList&)
  find_query() <| $ [es] (game_objects : GameObjects)
    game_objects |> get_scene_game_objects_by_name("indoor_walls") |> for_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
      indoorBoxes__transforms |> push(tm)
      return true
    game_objects |> get_scene_game_objects_by_name("envi_probe_box") |> for_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
      indoorBoxes__transforms |> push(tm)
      return true
    return true
