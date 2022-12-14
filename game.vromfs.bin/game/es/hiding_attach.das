require ecs
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted


def remove_from_hiding_list(var hide_from_nodes : StringList;
                            node_name_to_remove : string)
  for idx, item in range(length(hide_from_nodes)), hide_from_nodes
    if item == node_name_to_remove
      hide_from_nodes |> erase(idx)
      break


def gather_children_nodes_indices(tree : GeomNodeTree;
                                  node : uint16;
                                  var out : UInt16List&)
  out |> push(node)
  let childCount = tree |> geomtree_getChildCount(int(node))
  for i in range(childCount)
    gather_children_nodes_indices(tree, uint16(tree |> geomtree_getChildNodeIdx(int(node), uint(i))), out)


def rebuild_hiding_list(hide_from_nodes : StringList;
                        var hiding_attach__childrenIds : UInt16List&;
                        tree : GeomNodeTree)
  hiding_attach__childrenIds |> clear()
  for item in hide_from_nodes
    let firstIdx = tree |> geomtree_findNodeIndex(string(item))
    if firstIdx < 0
      continue
    gather_children_nodes_indices(tree, uint16(firstIdx), hiding_attach__childrenIds)


def restore_hidden_nodes(hiding_attach__childrenIds : UInt16List;
                         var animchar : AnimcharBaseComponent&)
  for idx in hiding_attach__childrenIds
    geomtree_getNodeTm(*animchar.nodeTree, int(idx)) = geomtree_getNodeTm(*animchar.originalNodeTree, int(idx))
  animchar |> animchar_doRecalcAnimAndWtm()


[es(tag=server, on_appear, track=(slot_attach__attachedTo, base_vis_item__hideNodesInEntity))]
def hiding_attach_track_es_event_handler(evt : Event;
                                         slot_attach__attachedTo : EntityId;
                                         base_vis_item__hideFromNode : StringList;
                                         var base_vis_item__hideNodesInEntity : EntityId&)
  if slot_attach__attachedTo == base_vis_item__hideNodesInEntity
    return

  if doesEntityExist(base_vis_item__hideNodesInEntity)
    for node in base_vis_item__hideFromNode
      sendEvent(base_vis_item__hideNodesInEntity, [[CmdClearHiddenNode nodeName=string(node)]])

  if doesEntityExist(slot_attach__attachedTo)
    for node in base_vis_item__hideFromNode
      sendEvent(slot_attach__attachedTo, [[CmdSetHideNode nodeName=string(node)]])

  base_vis_item__hideNodesInEntity = slot_attach__attachedTo


[es(tag=server, on_disappear, REQUIRE=slot_attach__attachedTo)]
def disappear_attach_track_es_event_handler(evt : Event;
                                            base_vis_item__hideFromNode : StringList;
                                            var base_vis_item__hideNodesInEntity : EntityId&)
  if doesEntityExist(base_vis_item__hideNodesInEntity)
    for node in base_vis_item__hideFromNode
      sendEvent(base_vis_item__hideNodesInEntity, [[CmdClearHiddenNode nodeName=string(node)]])

  base_vis_item__hideNodesInEntity = INVALID_ENTITY_ID


[es(tag=server)]
def hiding_attach_parent_add_es_event_handler(evt : CmdSetHideNode;
                                              var hiding_attach__hideFromNodes : StringList&)
  hiding_attach__hideFromNodes |> push(evt.nodeName)


[es(tag=server)]
def hiding_attach_parent_del_es_event_handler(evt : CmdClearHiddenNode;
                                              var hiding_attach__hideFromNodes : StringList&)
  remove_from_hiding_list(hiding_attach__hideFromNodes, evt.nodeName)


[es(on_appear, track=hiding_attach__hideFromNodes)]
def hiding_attach_fill_es_event_handler(evt : Event;
                                        hiding_attach__hideFromNodes : StringList;
                                        var animchar : AnimcharBaseComponent&;
                                        var hiding_attach__childrenIds : UInt16List&;
                                        var hiding_attach__enabled : bool&)
  restore_hidden_nodes(hiding_attach__childrenIds, animchar)
  rebuild_hiding_list(hiding_attach__hideFromNodes, hiding_attach__childrenIds, *animchar.nodeTree)
  hiding_attach__enabled = !empty(hiding_attach__hideFromNodes)


[es(tag=gameClient, after=slot_attach_copy_wtm_es, REQUIRE=hiding_attach__enabled)]
def hiding_attach_process_es(evt : UpdateStageInfoBeforeRender;
                             hiding_attach__childrenIds : UInt16List;
                             var animchar : AnimcharBaseComponent&;
                             var animchar_node_wtm : AnimcharNodesMat44&;
                             var animchar_render__root_pos : vec4f&)
  if hiding_attach__childrenIds |> empty()
    return

  assume tree = animchar.nodeTree
  for idx in hiding_attach__childrenIds
    *tree |> geomtree_setNodeTmScalar(int(idx), float3x4()) // set tm to ZERO<TMatrix>()
    *tree |> geomtree_invalidateWtm()

  animchar |> animchar_recalc_wtm()
  animchar |> animchar_copy_nodes(animchar_node_wtm, animchar_render__root_pos)
