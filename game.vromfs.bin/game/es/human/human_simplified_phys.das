require ecs

[es(track=beh_tree__enabled, on_appear)]
def enable_simplified_query_walk_position_on_bots_es(evt : Event;
                                                     beh_tree__enabled : bool;
                                                     var human_net_phys__isSimplifiedQueryWalkPosition : bool&)
  human_net_phys__isSimplifiedQueryWalkPosition = beh_tree__enabled