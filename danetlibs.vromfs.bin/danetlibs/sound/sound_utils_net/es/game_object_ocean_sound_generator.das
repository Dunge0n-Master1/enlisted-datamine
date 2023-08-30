require ecs
require ecs.safe
require ecs.extra_set
require gameObject


[es(tag=server, on_appear, on_event=EventGameObjectsCreated)]
def game_object_ocean_sound_generator(evt : Event;
                                      game_object_ocean_sound_generator__gameObjects : StringList;
                                      game_object_ocean_sound_generator__entityTemplate : string;
                                      var game_object_ocean_sound_generator__entityEid : EntityId&)

  var points : array<float3>

  find_query() <| $ [es] (game_objects : GameObjects)
    for gameObject in game_object_ocean_sound_generator__gameObjects
      let scene = game_objects |> get_scene_game_objects_by_name(string(gameObject))
      if scene != null
        let firstPointIdx = length(points)
        scene |> find_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
          points |> reserve(32)
          points |> push(float3(tm[3].x, tm[3].z, 0.))
          return false
        if length(points) > firstPointIdx
          let pt = points[firstPointIdx]
          points |> push(pt)
    return true

  if !!game_object_ocean_sound_generator__entityEid
    destroyEntity(game_object_ocean_sound_generator__entityEid)
  game_object_ocean_sound_generator__entityEid = INVALID_ENTITY_ID

  if !empty(points)
    game_object_ocean_sound_generator__entityEid = createEntity(game_object_ocean_sound_generator__entityTemplate) <| $(var init)
      init |> set("ocean_sound__points", points)
