require ecs
require ecs.safe
require ecs.extra_set
require gameObject
require soundHash


[es(tag=server, on_appear, on_event=EventGameObjectsCreated)]
def game_object_compound_sound_generator(evt : Event;
                                         game_object_compound_sound_generator__entityTypes : Array;
                                         var game_object_compound_sound_generator__eids : EidList&)

  for eid in game_object_compound_sound_generator__eids
    destroyEntity(eid)
  clear(game_object_compound_sound_generator__eids)

  find_query() <| $ [es] (game_objects : GameObjects)
    for entityTypeIt in game_object_compound_sound_generator__entityTypes
      let entityType = entityTypeIt as Object

      var volumes : array<float3x4>
      var shapes : array<uint>

      let objectTypes = entityType?.objectTypes ?as Object
      for it in *objectTypes
        let gameObjectType = it.key
        let scene = game_objects |> get_scene_game_objects_by_name(string(gameObjectType))
        if scene != null
          scene |> find_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
            let t : float3x4 := tm
            volumes |> push(t)
            let shape = get_ecs_string(it.value)
            shapes |> push(sound_hash(shape != null ? string(*shape) : "box"))
            return false

      if length(volumes) == 1 || (entityType?.forceSingleEntityTemplate ?? false)
        let entityTemplate = entityType?.singleEntityTemplate ?? ""
        let soundName = entityType?.soundName ?? ""
        for tm, shape in volumes, shapes
          let eid = createEntity(entityTemplate) <| $(var init)
            init |> set("transform", tm)
            init |> set("game_object_sound__shape", shape)
            init |> set("game_object_sound__name", soundName)
          push(game_object_compound_sound_generator__eids, eid)

      elif !empty(volumes)
        let entityTemplate = entityType?.compoundEntityTemplate ?? ""
        let soundName = entityType?.soundName ?? ""
        let eid = createEntity(entityTemplate) <| $(var init)
          init |> set("game_object_compound_sound__transforms", volumes)
          init |> set("game_object_compound_sound__shapes", shapes)
          init |> set("game_object_sound__name", soundName)
        push(game_object_compound_sound_generator__eids, eid)

    return true
