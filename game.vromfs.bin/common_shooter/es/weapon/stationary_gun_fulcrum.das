require ecs
require AnimV20
require DagorSystem
require GeomNodeTree

[es(on_appear)]
def stationary_gun_fulcrum__node_init(evt : Event;
                                      var stationary_gun_fulcrum__nodeId : int&;
                                      animchar : AnimcharBaseComponent;
                                      stationary_gun_fulcrum__node = "mg_bipod")
  stationary_gun_fulcrum__nodeId = geomtree_findNodeIndex(animchar.nodeTree, stationary_gun_fulcrum__node)
  if (stationary_gun_fulcrum__nodeId < 0)
    logerr("Can't find stationary_gun_fulcrum node {stationary_gun_fulcrum__node}");