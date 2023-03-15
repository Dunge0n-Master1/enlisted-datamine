require ecs
require game.es.events
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

[es(after=after_animchar_update_sync, before=animchar_render_es)]
def node_attached_itm(info : ParallelUpdateFrameDelayed;
                      node_attached__entity : EntityId;
                      node_attached__nodeId : int;
                      node_attached__localTm : float3x4;
                      var transform : float3x4&)
  if node_attached__nodeId < 0
    return

  query(node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, tm)
    transform = tm * node_attached__localTm

[es(after=after_animchar_update_sync, before=animchar_render_es)]
def node_attached_pos(info : ParallelUpdateFrameDelayed;
                      node_attached__entity : EntityId;
                      node_attached__nodeId : int;
                      node_attached__localPos : float3;
                      var transform : float3x4&)
  if node_attached__nodeId < 0
    return

  query(node_attached__entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, tm)
    transform[3] = tm * node_attached__localPos

[es(tag=server, tag=net, no_order, REQUIRE=node_attached__destroyWithParent)]
def node_attached_destroy_with_parent_server(info : ParallelUpdateFrameDelayed; eid : EntityId; node_attached__entity : EntityId)
  if !doesEntityExist(node_attached__entity)
    destroyEntity(eid)

[es(no_order, REQUIRE=node_attached__destroyWithParent, REQUIRE_NOT=replication)]  // same as above ES but for local (not networking) entities
def node_attached_destroy_with_parent_local(info : ParallelUpdateFrameDelayed; eid : EntityId; node_attached__entity : EntityId)
  if !doesEntityExist(node_attached__entity)
    destroyEntity(eid)

[es(tag=gameClient, after=node_attached_itm, before=animchar_render_es, REQUIRE=node_attached__updateWtm)]
def node_attached_update_animchar_es(info : ParallelUpdateFrameDelayed;
                                     transform : float3x4;
                                     node_attached__nodeId : int;
                                     var animchar : AnimcharBaseComponent;
                                     var animchar_node_wtm : AnimcharNodesMat44&;
                                     var animchar_render__root_pos : vec4f&)
  if node_attached__nodeId < 0
    return
  animchar_set_tm(animchar, transform, true)
  animchar_recalc_wtm(animchar)
  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
