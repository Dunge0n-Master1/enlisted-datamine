require ecs
require DagorSystem
require app
require CollRes

[es(on_appear)]
def fire_attach_excludes_init(evt : Event;
                              collres : CollisionResource;
                              var fire_attach_excludes__nodeIds : IntList&;
                              fire_attach_excludes__nodeNames : StringList)
  for pattern in fire_attach_excludes__nodeNames
    let node = collres_get_node_index_by_name(collres, string(pattern))
    if node >= 0
      push(fire_attach_excludes__nodeIds, node)