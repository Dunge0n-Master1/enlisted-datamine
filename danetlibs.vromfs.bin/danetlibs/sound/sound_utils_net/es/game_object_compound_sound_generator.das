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

      var transforms : array<float3x4>
      var shapes : array<string>

      let objectTypes = entityType?.objectTypes ?as Object
      for it in *objectTypes
        let gameObjectType = it.key
        let scene = game_objects |> get_scene_game_objects_by_name(string(gameObjectType))
        if scene != null
          scene |> find_scene_game_objects() <| $ [unused_argument(ni)] (ni : uint; tm : float3x4#)
            let t : float3x4 := tm
            transforms |> push(t)
            let shape = get_ecs_string(it.value)
            shapes |> push(shape != null ? string(*shape) : "box")
            return false

      if length(transforms) == 1
        let entityTemplate = entityType?.singleEntityTemplate ?? "volume_ambient_sound"
        let soundName = entityType?.soundName ?? ""
        for tm, shape in transforms, shapes
          let eid = createEntity("{entityTemplate}+{shape}_sound_shape") <| $(var init)
            init |> set("transform", tm)
            init |> set("game_object_sound__name", soundName)
          push(game_object_compound_sound_generator__eids, eid)
      elif !empty(transforms)
        let entityTemplate = entityType?.compoundEntityTemplate ?? "compound_ambient_sound"
        let soundName = entityType?.soundName ?? ""
        let eid = createEntity(entityTemplate) <| $(var init)

          var hashes : array<uint>
          hashes |> resize(length(shapes))

          for shape, hash in shapes, hashes
            hash = sound_hash(shape)

          init |> set("game_object_compound_sound__shapes", hashes)
          init |> set("game_object_compound_sound__transforms", transforms)
          init |> set("game_object_sound__name", soundName)
        push(game_object_compound_sound_generator__eids, eid)

    return true
