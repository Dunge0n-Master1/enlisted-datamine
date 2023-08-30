require ecs

[es(tag=server, on_appear)]
def prefab_init_objects_by_id_es(evt : Event;
                                 transform aka parent_transform : float3x4;
                                 prefab__id : int)
  query() <| $ [es] (transform : float3x4;
                     prefab__parentId : int;
                     var prefab__localTm : float3x4&)
    if prefab__id != prefab__parentId
      return
    prefab__localTm = inverse(parent_transform) * transform

[es(tag=server, on_appear)]
def init_prefab_object_by_id_es(evt : Event;
                                prefab__parentId : int;
                                transform aka child_transform : float3x4;
                                var prefab__localTm : float3x4&)
  find_query() <| $ [es] (prefab__id : int; transform : float3x4)
    if prefab__parentId != prefab__id
      return false
    prefab__localTm = inverse(transform) * child_transform
    return true
