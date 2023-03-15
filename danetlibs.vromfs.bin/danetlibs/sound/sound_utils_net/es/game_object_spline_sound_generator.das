require ecs
require ecs.safe
require ecs.extra_set
require gameObject


[es(tag=server, on_appear, on_event=EventGameObjectsCreated)]
def game_object_spline_sound_generator(evt : Event;
                                       game_object_spline_sound_generator__gameObjects : StringList;
                                       game_object_spline_sound_generator__entityTemplate : string;
                                       game_object_spline_sound_generator__pointRadiusMul : float;
                                       var game_object_spline_sound_generator__entityEid : EntityId&)

  var points : array<float4>

  find_query() <| $ [es] (game_objects : GameObjects)
    for gameObject in game_object_spline_sound_generator__gameObjects
      let scene = game_objects |> get_scene_game_objects_by_name(string(gameObject))
      if scene != null
        var isFirstPointInSpline = true
        scene |> find_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
          points |> reserve(16)
          if isFirstPointInSpline && !empty(points)
            points |> push(float4(0., 0., 0., -1.)) // separator for a new spline
          isFirstPointInSpline = false
          let pos = tm[3]
          let radius = length(tm[0]) * 0.5 * game_object_spline_sound_generator__pointRadiusMul
          points |> push(float4(pos.x, pos.y, pos.z, radius))
          return false
    return true

  if !!game_object_spline_sound_generator__entityEid
    destroyEntity(game_object_spline_sound_generator__entityEid)
  game_object_spline_sound_generator__entityEid = INVALID_ENTITY_ID

  if !empty(points)
    game_object_spline_sound_generator__entityEid = createEntity(game_object_spline_sound_generator__entityTemplate) <| $(var init)
      init |> set("spline_sound__points", points)
